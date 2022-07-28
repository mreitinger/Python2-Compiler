use Python2::AST;
use Digest::SHA1::Native;
use Data::Dump;
use Python2::ParseFail;

class Python2::Backend::Perl5 {
    has Str $!o = '';
    has Str $!modules = '';
    has Str $.embedded; # class name to use as 'main' class.
                        # used when embedding the code in some other environment where the caller
                        # needs to know the main class name
                        # if this is set the call to main->block() is not included in the output
                        # and is left for the caller to execute so parameters can be passed.


    has Str $!wrapper = q:to/END/;
        use v5.26.0;
        use strict;
        use lib qw( p5lib );

        %s

        package Python2::Type::Class::main_%s {
            use Python2;
            use base 'Python2::Type::Main';

            # return the source of the original python file
            sub __source__ {
        return <<'PythonInput%s';
        %s
        PythonInput%s
            }

            sub __block__ {
                my ($self, $args) = @_;
                my $stack = $self->{stack};

                while(my ($key, $value) = each(%%$args)) {
                    setvar($stack, $key, ${ convert_to_python_type($value) });
                }

                %s
            }
        }
        END

    # code to auto-execute our main block. used for script execution and skipped when embedding
    has Str $!autoexec = q:to/END/;
        my $py2main = Python2::Type::Class::main_%s->new();
        $py2main->__run__();
        END

    # we use an array instead of a hash for faster lookups.
    # Layout:
    #[
    #    $parent,    # reference to parent stack
    #    {           # items in our scope
    #       name1 => value1,
    #       name2 => value2
    #    },
    #]

    # root node: iteral over all statements and create perl code for them
    multi method e(Python2::AST::Node::Root $node) {
        for ($node.nodes) {
            $!o ~= $.e($_);
        }

        # sha1 hash of our input - used to identify the main clas
        my Str $class_sha1_hash = sha1-hex($node.input);

        my Str $output = sprintf(
            $!wrapper,          # wrapper / sprintf definition
            $!modules,          # python class definitions

            # name of the main package. provided when we get embedded or auto generated from sha1 hash
            $.embedded ?? $.embedded !! $class_sha1_hash,

            $class_sha1_hash,   # sha1 hash for source heredoc start
            $node.input,        # python2 source code for exception handling
            $class_sha1_hash,   # sha1 hash for source heredoc end
            $!o,                # block of main body
        );

        unless ($.embedded) {
            $output ~= sprintf($!autoexec, $class_sha1_hash);
        }

        return $output;
    }

    multi method e(Python2::AST::Node::Atom $node) {
        if ($node.expression ~~ Python2::AST::Node::Name) {
            return sprintf('getvar($stack, %s)', $.e($node.expression));
        } else {
            return sprintf('%s', $.e($node.expression));
        }
    }

    multi method e(Python2::AST::Node::Statement::P5Import $node) {
        return sprintf('setvar($stack, \'%s\', sub { my $object = Python2::Type::PerlObject->new(\'%s\'); return \$object; });',
            $node.name,
            $node.perl5-package-name.subst("'", "\\'", :g),
        );
    }

    multi method e(Python2::AST::Node::Name $node) {
        return sprintf("'%s'", $node.name.subst("'", "\\'", :g));
    }

    multi method e(Python2::AST::Node::ArgumentList $node) {
        my @positional-arguments;
        my @named-arguments;

        for $node.arguments -> $argument {
            if $argument.name {
                @named-arguments.append($argument);
            }
            else {
                # TODO die for mixed arguments
                @positional-arguments.append($argument);
            }
        }

        my Str $p5 = '';

        if @positional-arguments {
            # positional arguments get passed as regular arguments to the perl sub
            $p5 ~= @positional-arguments.map({ '${' ~ $.e($_) ~ '}' }).join(', ');
            $p5 ~= ','; # to accomodate a possible named argument hashref
        }

        # named arguments get passed as a hashref to the perl method. this is allways passed as the
        # last argument and will be pop()'d before processing any other arguments.
        $p5 ~= '{' ~ @named-arguments.map({ $.e($_.name) ~ ' => ' ~ $.e($_.value) }).join(',') ~ '}';

        return $p5;
    }

    multi method e(Python2::AST::Node::Argument $node) {
        return $.e($node.value);
    }

    # Statements
    # statement 'container': if it's a statement append ; to make the perl parser happy
    multi method e(Python2::AST::Node::Statement $node) {
        my Str $p5  = qq|\n# line 999 "___position_{$node.start-position}_{$node.end-position}___"\n|;
               $p5 ~= $.e($node.statement) ~ ";\n";
    }

    multi method e(Python2::AST::Node::Statement::Print $node) {
        return sprintf('py2print(${ %s }, {})', $.e($node.value));
    }

    multi method e(Python2::AST::Node::Statement::Raise $node) {
        return sprintf('raise(${ %s }, {})', $.e($node.value));
    }

    multi method e(Python2::AST::Node::Statement::VariableAssignment $node) {
        Python2::ParseFail.new(:pos($node.start-position), :what("Expected name")).throw()
            unless ($node.target.atom.expression ~~ Python2::AST::Node::Name);

        # see AST::Node::Power
        $node.target.must-resolve = False;

        return sprintf('${%s} = ${%s}',
            $.e($node.target),
            $.e($node.expression)
        );
    }

    multi method e(Python2::AST::Node::Statement::ArithmeticAssignment $node) {
        my $operator = $node.operator.chop; # grammar ensures only valid operators pass thru here

        return sprintf(q|${%s} = ${ arithmetic(${ %s }, ${ %s }, '%s') }|,
            $.e($node.target),
            $.e($node.target),
            $.e($node.value),
            $operator
        );
    }

    multi method e(Python2::AST::Node::Statement::Return $node) {
        return  $node.value
                ??  sprintf('return %s', $.e($node.value))
                !!  'return';
    }



    # loops
    multi method e(Python2::AST::Node::Statement::LoopFor $node) {
        my Str $p5;

        $p5 ~= sprintf('my $i = ${ %s };', $.e($node.iterable));

        if ($node.names.elems > 1) {
            # TODO should support all iterables
            $p5 ~= 'die Python2::Type::Exception->new("TypeError", "expected enumerate but got " . $i->__type__) unless ($i->__type__ eq "enumerate");';

            $p5 ~= q:to/END/;
                while(1) {
                    my $var;
                    eval {
                        $var = ${ $i->next() };

                        die Python2::Type::Exception->new('TypeError', 'tuple expected but got ' . $var->__type__)
                            unless $var->__type__ eq 'tuple';
                END

            $p5 ~= sprintf('die Python2::Type::Exception->new("ValueError", "size of tuple does not match loop declaration") unless scalar(@$i) == %i;', $node.names.elems);

            my Int $index = 0;
            for $node.names -> $name {
                $p5 ~= sprintf('setvar($stack, %s, $var->[%i]);', $.e($name), $index++);
            }

            $p5 ~= sprintf('%s', $.e($node.block));

            $p5 ~= q:to/END/;
                    }
                    or do {
                        if ($@ eq 'StopIteration') { last } else { die; }
                    }
                }
                END
        }
        else {
            # single name, raw values from a list/tuple
            $p5 ~= 'foreach my $var (@{$i}) {';
            $p5 ~= sprintf('setvar($stack, %s, $var);', $.e($node.names[0]));
            $p5 ~= sprintf('%s }', $.e($node.block));
        }



        return $p5;
    }

    multi method e(Python2::AST::Node::ListComprehension $node) {
        my Str $p5;

        $p5 ~= sprintf('do { my $i = ${ %s };', $.e($node.iterable));
        $p5 ~= 'my $r = Python2::Type::List->new();';

        $p5 ~= 'foreach my $var (@{$i}) {';
        $p5 ~= sprintf('setvar($stack, %s, $var);', $.e($node.name));

        $p5 ~= sprintf('next unless ${ %s }->__tonative__;', $.e($node.test))
            if ($node.test);

        $p5 ~= sprintf('$r->__iadd__(${ %s });', $.e($node.expression));
        $p5 ~= '}';

        return $p5 ~ 'return \$r; }';
    }

    multi method e(Python2::AST::Node::Statement::TryExcept $node) {
        my $p5 = sprintf('eval { %s } or do { %s };',
            $.e($node.try-block),
            $.e($node.except-block),
        );

        $p5 ~= sprintf('; { %s }', $.e($node.finally-block)) if $node.finally-block;

        return $p5;
    }

    multi method e(Python2::AST::Node::Test $node) {
        my $p5;

        if ($node.condition) {
            $p5 ~= sprintf(
                'sub { my $p = %s; $$p // die Python2::Type::Exception->new("NameError", "TODO - varname"); ref($$p) eq "CODE" ? $p :$$p->__tonative__; }->() ? ',
                $.e($node.condition)
            );
        }

        $p5 ~= sprintf('sub { my $p = %s; $$p // die Python2::Type::Exception->new("NameError", "TODO - varname"); $p; }->()', $.e($node.left));

        if ($node.condition) {
            $p5 ~= sprintf(': sub { my $p = %s; $$p // die Python2::Type::Exception->new("NameError", "TODO - varname"); $p; }->()', $.e($node.right));
        }

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::If $node) {
        my Str $p5 = qq|\n# line 999 "___position_{$node.start-position}_{$node.block.start-position}___"\n|;

        $p5 ~= sprintf('if ( ${ %s }->__tonative__ ) { %s }', $.e($node.test), $.e($node.block));

        for $node.elifs -> $elif {
            $p5 ~= $.e($elif);
        }

        $p5 ~= sprintf('else { %s }', $.e($node.else)) if $node.else;

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::ElIf $node) {
        return sprintf('elsif (${ %s }->__tonative__) { %s }', $.e($node.test), $.e($node.block));
    }

    multi method e(Python2::AST::Node::Statement::Test::Comparison $node) {
        if ($node.right) {
            return sprintf('${%s}->%s(${%s})',
                $.e($node.left),
                $node.comparison-operator,
                $.e($node.right),
            );
        } else {
            return $.e($node.left);
        }
    }

    multi method e(Python2::AST::Node::Test::Logical $node) {
        return $.e($node.left) unless $node.condition;

        if ($node.condition.condition eq 'not') {
            return sprintf('\Python2::Type::Scalar::Bool->new(not ${%s}->__tonative__)', $.e($node.left));
        }
        elsif ($node.condition.condition eq 'or') {
            sprintf('do { my $l = %s; my $r = %s; $$l->__tonative__ ? $l : $r; }', $.e($node.left), $.e($node.right))
        }
        else {
            return $node.condition
                ?? sprintf('\Python2::Type::Scalar::Bool->new(${%s}->__tonative__ %s ${%s}->__tonative__)', $.e($node.left), $.e($node.condition), $.e($node.right))
                !! $.e($node.left);
        }
    }

    multi method e(Python2::AST::Node::Test::LogicalCondition $node) {
        return sprintf('%s', $node.condition);
    }

    multi method e(Python2::AST::Node::Statement::FunctionDefinition $node) {
        my $p5 = sprintf(
            'setvar($stack, \'%s\', sub {',
            $node.name.name.subst("'", "\\'", :g)
        );

        # local stack frame for this function
        $p5 ~= 'my $stack = [$builtins];' ~ "\n";

        # argument definition containing, if present, default vaules
        my Str $argument-definition = '';
        for $node.argument-list -> $argument {
            $argument-definition  ~= sprintf('[ \'%s\', %s ],',
                $argument.name.name,
                $argument.default-value ?? $.e($argument.default-value) !! 'undef',
            );
        }

        # call Python2::getopt() to parse our arguments
        $p5 ~= sprintf('getopt($stack, \'%s\', [%s], @_);',
            $node.name.name.subst("'", "\\'", :g),
            $argument-definition
        );

        # the code block (body) of the function
        $p5   ~= $.e($node.block);

        $p5   ~= 'return \""';     # if $node.block contains a return statement it will execute before this
                                   # TODO this should return some Nonetype object?
                                   # TODO on python this returns None but if we return undef this would hit the NameError
                                   # TODO check further down. this is still wrong but at least it returns 'false'

        $p5   ~= "})";
    }

    multi method e(Python2::AST::Node::LambdaDefinition $node) {
        my $p5 = '\sub {${ ';

        $p5 ~= 'my $stack = [$stack];' ~ "\n";
        #TODO check this

        for $node.argument-list -> $argument {
            $p5 ~= sprintf('setvar($stack, \'%s\', shift @_);',$argument.name.name);
        }

        $p5   ~= sprintf('my $retvar = %s; return $retvar;', $.e($node.block));
        $p5   ~= "}}"
    }

    multi method e(Python2::AST::Node::Statement::ClassDefinition $node) {
        my Str $perl5_class_name = 'Python2::Type::Class::class_' ~ sha1-hex($node.name.name ~ $.e($node.block));
        my Str $preamble = 'use Python2;';

        $!modules ~= sprintf(
            'package %s { use base qw/ Python2::Type::Object /; %s sub __build__ { my $self = shift; my $stack = $self->{stack}; %s; return $self; } }',
            $perl5_class_name,
            $preamble,
            $.e($node.block)
                                      );

        return sprintf('setvar($stack, \'%s\', sub { my $object = %s->new(); return \$object; });',
            $node.name.name.subst("'", "\\'", :g),
            $perl5_class_name,
        );
    }


    # Expressions
    multi method e(Python2::AST::Node::Expression::Container $node) {
        return $.e($node.expression);
    }

    # this implementation does not account for some of the more complex constructs like chaining function calls
    # to call returned references to functions:
    #
    # def foo():
    #     def bar():
    #         print 1
    #
    # return bar
    #
    # foo()()
    #
    # to handle this way more complicated code needs to be generated, see this method around b76c82b3ff351510adb9d7de3da34bc630ea55cc
    # which did not handle calling methods on perl objects.

    multi method e(Python2::AST::Node::Power $node) {
        my @elements = ($node.atom, $node.trailers).flat;

        my Str $p5 = 'my $p;';

        # simple function-call. we handle this first so we produce simpler code and
        # don't conflict with method calls down below
        if @elements.elems == 2 and @elements[1] ~~ Python2::AST::Node::ArgumentList {
            $p5 ~= sprintf('$p = %s;', $.e(@elements[0]));

            $p5 ~= sprintf(q|$$p or die Python2::Type::Exception->new("NameError", "name '%s' is not defined");|, @elements[0].expression.name)
                if $node.must-resolve;

            $p5 ~= sprintf('$$p->(%s);', $.e(@elements[1]));

            return sprintf('sub{ %s }->()', $p5);
        }

        # single atom
        if (@elements.elems == 1) {
            $p5 ~= sprintf('$p = %s;', $.e(@elements[0]));

            $p5 ~= sprintf(q|$$p or die Python2::Type::Exception->new("NameError", "name '%s' is not defined");|, @elements[0].expression.name)
                if ($node.must-resolve and @elements[0].expression ~~ Python2::AST::Node::Name);

            return sprintf('sub{ %s; return $p; }->()', $p5);
        }


        # chained expressions
        while @elements.elems > 0 {
            my $current-element = @elements.shift;
            my $next-element = @elements.first;

            if $current-element ~~ Python2::AST::Node::Name and $next-element ~~ Python2::AST::Node::ArgumentList {
                my $argument-list = @elements.shift;

                $p5 ~= sprintf('$p = ${$p}->%s(%s);',
                    $current-element.name,
                    $.e($argument-list)
                );
            }
            elsif $current-element ~~ Python2::AST::Node::Subscript {
                $p5 ~= $current-element.target
                    ?? sprintf('$p = ${$p}->__getslice__(%s, {});', $.e($current-element)) # array slice
                    !! sprintf('$p = ${$p}->__getitem__(%s, {});', $.e($current-element));
            }
            elsif $current-element ~~ Python2::AST::Node::Name {
                $p5 ~= sprintf('$p = ${$p}->__getattr__(%s, {});', $.e($current-element));
                $p5 ~= sprintf(q|$$p or die Python2::Type::Exception->new("AttributeError", "no attribute '%s'");|, $current-element.name)
                    if ($node.must-resolve or @elements.elems > 0) and ($current-element ~~ Python2::AST::Node::Name);
            }
            else {
                $p5 ~= sprintf('$p = %s;', $.e($current-element));
                $p5 ~= sprintf(q|$$p or die Python2::Type::Exception->new("NameError", "name '%s' is not defined");|, $current-element.expression.name)
                    if ($node.must-resolve or @elements.elems > 0) and ($current-element.expression ~~ Python2::AST::Node::Name);
            }
        }

        return sprintf('sub{my $p = undef; %s; return $p; }->()', $p5);
    }

    multi method e(Python2::AST::Node::Expression::ArithmeticExpression $node) {
        my $p5;

        my @operations = $node.operations.clone;

        # initial left element
        my $left-element = @operations.shift;

        my $operation;
        my $right-element;

        $p5 ~= sprintf('sub { my $left = %s;', $.e($left-element));

        while @operations.elems {
            $operation      = @operations.shift;
            $right-element  = @operations.shift;

            given $right-element {
                when ($_ ~~ Python2::AST::Node::Power) and ($_.atom.expression ~~ Python2::AST::Node::Expression::TestList) {
                    # it's probably a string interpolation with multiple arguments like
                    #   '%s %s' (1, 2)
                    # since that gets parsed as a TestList we extract it here
                    $right-element = sprintf('\Python2::Type::List->new(%s)',
                        $right-element.atom.expression.tests.values.map({ sprintf('${ %s }', $.e($_)) }).join(', ')
                    ),
                }
                default {
                    $right-element = $.e($right-element)
                }
            }

            $p5 ~= sprintf(
                q|$left = arithmetic(${ $left }, ${ %s }, '%s');|,
                $right-element,
                $.e($operation)
            );
        }

        $p5 ~= 'return $left; }->();';

        return $p5;
    }

    multi method e(Python2::AST::Node::Expression::ArithmeticOperator $node) {
        return $node.arithmetic-operator;
    }

    multi method e(Python2::AST::Node::Expression::Literal::String $node) {
        # TODO various escape sequences
        my $string = $node.value
            .subst('\"',    '"',    :g)
            .subst('\\\'',  "'",    :g)
        ;

        # r'string' (python raw strings)
        unless $node.raw {
            $string = $string
                .subst('\\\\',  '\\',   :g)
                .subst('\\n',   "\n",   :g)
                .subst('\\t',   "\t",   :g);
        }

        my $p5;

        $p5 ~= "\nsub \{ my \$s = <<'MAGICendOfStringMARKER';\n";
        $p5 ~= $string;
        $p5 ~= "\nMAGICendOfStringMARKER\n; chomp(\$s); return \\Python2::Type::Scalar::String->new(\$s); }->()";
    }

    multi method e(Python2::AST::Node::Expression::Literal::Integer $node) {
        return sprintf('convert_to_python_type(%s)', $node.value);
    }

    multi method e(Python2::AST::Node::Expression::Literal::Float $node) {
        return sprintf('convert_to_python_type(%s)', $node.value)
    }

    multi method e(Python2::AST::Node::Subscript $node) {
        return $node.target
            ?? sprintf('${ %s }, ${ %s }', $.e($node.value), $.e($node.target))
            !! sprintf('${ %s }', $.e($node.value));
    }

    # list handling
    multi method e(Python2::AST::Node::Expression::ExpressionList $node) {
        return sprintf('\Python2::Type::List->new(%s)',
            $node.expressions.map({
                '${' ~ self.e($_) ~ '}'
            }).join(', ')
       );
    }

    multi method e(Python2::AST::Node::Expression::TestList $node) {
        # if a tuple would only contain a single element python disregards the parenthesis
        # TODO python allowes the creation of single-element tuples by adding a comma "(1,)"

        return  $node.tests.elems > 1
                    ??  sprintf('\Python2::Type::Tuple->new(%s)',
                            $node.tests.map({ '${' ~ self.e($_) ~ '}' }).join(', ')
                        )
                    !!  sprintf('%s', $.e($node.tests[0]));
    }

    # dictionary handling
    multi method e(Python2::AST::Node::Expression::DictionaryDefinition $node) {
        return sprintf('\Python2::Type::Dict->new(%s)',
            $node.entries.map({
                '${' ~ $.e($_.key) ~ '} => ${' ~ $.e($_.value) ~ '}'
            }).join(', ')
       );
    }

    multi method e(Python2::AST::Node::Block $node) {
        return sprintf('{ %s }', $node.statements.map({
            self.e($_)
        }).join(''));
    }


    # Fallback
    multi method e($node) {
        die("Perl 5 backed for node not implemented: $node");
    }
}
