use Python2::AST;
use Digest::SHA1::Native;
use Data::Dump;

class Python2::Backend::Perl5 {
    has Str $!o = '';
    has Str $!modules = '';


    has Str $!wrapper = q:to/END/;
        use v5.26.0;
        use strict;
        use lib qw( p5lib );

        %s

        package python_class_main {
            use Data::Dumper;
            use Ref::Util::XS qw/ is_arrayref is_hashref is_coderef /;
            use Python2;

            use constant { PARENT => 0, ITEMS => 1 };

            sub new {
                return bless({ stack => [$builtins] }, 'python_class_main');
            }

            sub block { my $self = shift; my $stack = $self->{stack}; %s }
        }

        my $p2 = python_class_main->new();
        $p2->block();
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

        return sprintf($!wrapper, $!modules, $!o);
    }

    multi method e(Python2::AST::Node::Atom $node) {
        if ($node.expression ~~ Python2::AST::Node::Name) {
            return sprintf('getvar($stack, %s)', $.e($node.expression));
        } else {
            return sprintf('%s', $.e($node.expression));
        }
    }

    multi method e(Python2::AST::Node::Name $node) {
        return sprintf("'%s'", $node.name.subst("'", "\\'", :g));
    }

    multi method e(Python2::AST::Node::ArgumentList $node) {
        return sprintf('%s', $node.arguments.map({
            '${' ~ $.e($_) ~ '}'
        }).join(', '));
    }

    # Statements
    # statement 'container': if it's a statement append ; to make the perl parser happy
    multi method e(Python2::AST::Node::Statement $node) {
        return $.e($node.statement) ~ ";\n";
    }

    multi method e(Python2::AST::Node::Statement::Print $node) {
        return sprintf('py2print(${ %s })', $.e($node.value));
    }

    multi method e(Python2::AST::Node::Statement::VariableAssignment $node) {
        return sprintf('${%s} = ${%s}',
            $.e($node.target),
            $.e($node.expression)
                       );
    }

    multi method e(Python2::AST::Node::Statement::Return $node) {
        return sprintf('return %s', $.e($node.value));
    }



    # loops
    multi method e(Python2::AST::Node::Statement::LoopFor $node) {
        return sprintf('foreach my $var (@{ ${%s}->elements }) { setvar($stack, %s, $var); %s }',
            $.e($node.iterable),
            $.e($node.name),
            $.e($node.block),
        );
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
                '${ sub { my $p = %s; $$p // die("NameError" ); $p; }->() } ? ',
                $.e($node.condition)
                                            );
        }

        $p5 ~= sprintf('sub { my $p = %s; $$p // die("NameError" ); $p; }->()', $.e($node.left));

        if ($node.condition) {
            $p5 ~= sprintf(': sub { my $p = %s; $$p // die("NameError" ); $p; }->()', $.e($node.right));
        }

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::If $node) {
        my $p5 = sprintf('if (${ %s }) { %s }', $.e($node.test), $.e($node.block));

        $p5 ~= sprintf('else { %s }', $.e($node.else)) if $node.else;

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::Test::Comparison $node) {
        if ($node.right) {
            #tmp hack until we get this right
            return sprintf('compare(${%s}, ${%s}, \'%s\')',
                $.e($node.left),
                $.e($node.right),
                $node.comparison-operator
                           );
        } else {
            return $.e($node.left);
        }
    }

    multi method e(Python2::AST::Node::Test::Logical $node) {
        return $.e($node.left) unless $node.condition;

        if ($node.condition.condition eq 'not') {
            return sprintf('\not ${%s}', $.e($node.left));
        } else {
            return $node.condition
                ?? sprintf('\(${%s} %s ${%s})', $.e($node.left), $.e($node.condition), $.e($node.right))
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

        $p5 ~= 'my $stack = [$builtins];' ~ "\n";

        for $node.argument-list -> $argument {
            $p5 ~= sprintf('setvar($stack, \'%s\', shift @_);', $argument);
        }

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
            $p5 ~= sprintf('setvar($stack, \'%s\', shift @_);', $argument);
        }

        $p5   ~= sprintf('my $retvar = %s; return $retvar;', $.e($node.block));
        $p5   ~= "}}"
    }

    multi method e(Python2::AST::Node::Statement::ClassDefinition $node) {
        my Str $perl5_class_name = 'python_class_' ~ sha1-hex($node.name.name ~ $.e($node.block));
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

        # simple function-call. we handle this first so we produce simpler code and don't conflict with method calls
        # down below
        # TODO handle elemns == 1 up here and skip the sub{}
        if @elements.elems == 2 and @elements[1] ~~ Python2::AST::Node::ArgumentList {
            return sprintf('${ %s }->(%s)', $.e(@elements[0]), $.e(@elements[1]));
        }


        # chained expressions get wrapped in a sub{}
        my Str $p5 = '';
        while @elements.elems > 0 {
            my $current-element = @elements.shift;
            my $next-element = @elements.first;

            if $current-element ~~ Python2::AST::Node::Name and $next-element ~~ Python2::AST::Node::ArgumentList {
                my $argument-list = @elements.shift;
                $p5 ~= sprintf('$p = ${$p}->%s(%s);', $current-element.name, $.e($argument-list));
            }
            elsif $current-element ~~ Python2::AST::Node::Subscript {
                $p5 ~= sprintf('$p = ${$p}->element(${ %s });', $.e($current-element));
            }
            elsif $current-element ~~ Python2::AST::Node::Name {
                $p5 ~= sprintf('$p = ${$p}->__getattr__(%s);', $.e($current-element));
            }
            else {
                $p5 ~= sprintf('$p = %s;', $.e($current-element));
            }
        }

        return sprintf('sub{my $p = undef; %s}->()', $p5);
    }

    # TODO ArithmeticOperation's should probably(?) operate on Literal::Integer
    multi method e(Python2::AST::Node::Expression::ArithmeticOperation $node) {
        my $p5;

        for $node.operations -> $operation {
            if ($operation ~~ Python2::AST::Node::Expression::ArithmeticOperator) {
                $p5 ~= $.e($operation);
            } else {
                $p5 ~= '${' ~ $.e($operation) ~ '}';
            }
        }


        return 'sub { my $p = ' ~ $p5 ~ '; return \$p }->()';
    }

    multi method e(Python2::AST::Node::Expression::ArithmeticOperator $node) {
        return $node.arithmetic-operator;
    }

    multi method e(Python2::AST::Node::Expression::Literal::String $node) {
        return "\\'" ~ $node.value.subst("'", "\\'", :g) ~ "'";
    }

    multi method e(Python2::AST::Node::Expression::Literal::Integer $node) {
        return '\\' ~ $node.value;
    }

    multi method e(Python2::AST::Node::Expression::Literal::Float $node) {
        return '\\' ~ $node.value;
    }

    multi method e(Python2::AST::Node::Subscript $node) {
        return sprintf('%s', $.e($node.value));
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
        return $node.tests.map({
            $.e($_)
        }).join(' ');
    }


    # dictionary handling
    multi method e(Python2::AST::Node::Expression::DictionaryDefinition $node) {
        return sprintf('\Python2::Type::Dict->new(%s)',
            $node.entries.map({
                $_.key ~ '=> ${' ~ $.e($_.value) ~ '}'
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
        die("Perl 5 backed for node not implemented: " ~ Dump($node));
    }
}
