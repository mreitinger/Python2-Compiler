use Python2::AST;
use Digest::SHA1::Native;
use Data::Dump;
use Python2::ParseFail;

class Python2::Backend::Perl5 {
    has Str $!o = '';
    has Str %!modules;
    has $.compiler is required;


    # Wrapper used for complete scripts
    has Str $!script-wrapper = q:to/END/;
        use v5.26.0;
        use utf8;
        use strict;
        use lib qw( p5lib );

        %s

        package Python2::Type::Class::main_%s {
            use Python2;
            use Python2::Stack;
            use Python2::Internals;

            use base 'Python2::Type::Main';

            # return the source of the original python file
            sub __source__ {
        return <<'PythonInput%s';
        %s
        PythonInput%s
            }

            sub __block__ {
                my ($self, $args) = @_;
                my $stack = $self->[0];

                %s
            }
        }
        END

    # Wrapper used for modules
    has Str $!module-wrapper = q:to/END/;
        package Python2::Type::Class::main_%s {
            use Python2;
            use Python2::Internals;

            use base 'Python2::Type::Main';

            # return the source of the original python file
            sub __source__ {
        return <<'PythonInput%s';
        %s
        PythonInput%s
            }

            sub __block__ {
                my ($self, $args) = @_;
                my $stack = $self->[0];

                %s
            }
        }

        # run the one-off init code
        Python2::Type::Class::main_%s->new()->__run__();
        END

    # Wrapper used for expressions
    has Str $!expression-wrapper = q:to/END/;
        use v5.26.0;
        use utf8;
        use strict;
        use lib qw( p5lib );

        %s

        package Python2::Type::CodeObject::%s {

            use base 'Python2::Type::CodeObject';

            # return the source of the original python expression
            sub __source__ {
        return <<'PythonInput%s';
        %s
        PythonInput%s
            }

            sub __call__ {
                my ($self, $locals, $parent) = @_;

                my $stack = Python2::Stack->new(
                    Python2::Stack->new($Python2::builtins, $parent),
                    $locals
                );

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
    multi method e(
        Python2::AST::Node::Root $node,
        Bool :$module where { not $_ },
        Bool :$expression where { not $_ },
        Str :$embedded
    ) {
        for ($node.nodes) {
            $!o ~= $.e($_);
        }

        # sha1 hash of our input - used to identify the main clas
        my Str $class_sha1_hash = sha1-hex($node.input);

        my Str $output = sprintf(
            $!script-wrapper,               # wrapper / sprintf definition
            %!modules.values.join("\n"),    # python class definitions

            # name of the main package. provided when we get embedded or auto generated from sha1 hash
            $embedded ?? $embedded !! $class_sha1_hash,

            $class_sha1_hash,   # sha1 hash for source heredoc start
            $node.input,        # python2 source code for exception handling
            $class_sha1_hash,   # sha1 hash for source heredoc end
            $!o,                # block of main body
        );

        unless ($embedded) {
            $output ~= sprintf($!autoexec, $class_sha1_hash);
        }

        return $output;
    }

    # compile a single expression
    multi method e(
        Python2::AST::Node::Root $node,
        Bool :$expression where { $_ },
        Str  :$embedded!
    ) {
        for ($node.nodes) {
            $!o ~= $.e($_);
        }

        # sha1 hash of our input - used for heredoc delimiter
        my Str $class_sha1_hash = sha1-hex($node.input);

        my Str $output = sprintf(
            $!expression-wrapper,           # wrapper / sprintf definition

            %!modules.values.join("\n"),    # class definitions, in expressions only used for lambdas

            # name of the class, will be Python2::Type::CodeObject::$embedded
            $embedded,

            $class_sha1_hash,   # sha1 hash for source heredoc start
            $node.input,        # python2 source code for exception handling
            $class_sha1_hash,   # sha1 hash for source heredoc end
            $!o,                # block of main body
        );

        return $output;
    }

    # handles 'from <module> import <names>'
    multi method e(
        Python2::AST::Node::Root $node,     # the root node of our AST tree
        Bool :$module where { $_ },         # this method handles modules  - match where $module is true
        Str :$embedded is required,         # if we are compiling a module embedding must be set - see ::Compiler for details
        :@import-names is required,         # optional - list of names to limit what we import (from X import <imput-names>)
    ) {
        my Str $p5; # code for the complete module definition

        for $node.nodes -> $node {
            # restricted by grammar - sanity check only
            die("Expected statement") unless $node ~~ Python2::AST::Node::Statement;

            # code for the current statement
            my Str $p5-statement;

            # if it's some kind of definition import it to our namespace as long as the name matches and keep it
            # around for the one-off run of the init block
            if $node.statement ~~ Python2::AST::Node::Statement::FunctionDefinition {
                $p5-statement ~= $.e($node);
                $!o ~= $p5-statement if @import-names.grep($node.statement.name.name);
            }
            elsif $node.statement ~~ Python2::AST::Node::Statement::ClassDefinition {
                $p5-statement ~= $.e($node);
                $!o ~= $p5-statement if @import-names.grep($node.statement.name.name);
            }
            elsif $node.statement ~~ Python2::AST::Node::Statement::VariableAssignment {
                # the complete node, for initialization
                $p5-statement ~= $.e($node);


                # the filtered assignment, for our namespace
                $node.statement.name-filter = @import-names;
                $!o ~= $.e($node);
            }
            else {
                $p5-statement ~= $.e($node);
            }

            $p5 ~= $p5-statement;
        }

        # sha1 hash of our input - used to identify the main clas
        my Str $class_sha1_hash = sha1-hex($node.input);

        my Str $output = sprintf(
            $!module-wrapper,               # wrapper / sprintf definition

            # name of the main package. provided when we get embedded or auto generated from sha1 hash
            $embedded,

            $class_sha1_hash,   # sha1 hash for source heredoc start
            $node.input,        # python2 source code for exception handling
            $class_sha1_hash,   # sha1 hash for source heredoc end
            $p5,                # the main body of the module
            $embedded
        );

        return $output;
    }

    multi method e(Python2::AST::Node::Atom $node) {
        if ($node.expression ~~ Python2::AST::Node::Name) {
            return sprintf('Python2::Internals::getvar($stack, %i, %s)',
                $node.recurse
                    ?? 1
                    !! 0,
                $.e($node.expression)
            );
        } else {
            return sprintf('%s', $.e($node.expression));
        }
    }

    multi method e(Python2::AST::Node::Statement::P5Import $node) {
        return sprintf('Python2::Internals::setvar($stack, \'%s\', Python2::Type::PerlObject->new(\'%s\'));',
            $node.name,
            $node.perl5-package-name.subst("'", "\\'", :g),
        );
    }

    multi method e(Python2::AST::Node::Statement::FromImport $node) {
        my Str $p5;

        if %*ENV<PYTHONPATH> {
            my @search-paths = %*ENV<PYTHONPATH>.split(':');

            # module name is validated by grammar
            my $module-name = $node.name;
            $module-name ~~ s:g!\.!/!;

            # unique hash of the module and the requested objects
            my Str $import-sha1-hash = sha1-hex(
                $node.name ~
                $node.import-names.names.map({ $_.name }).join(' ')
            );

            # TODO this completly ignores __init__.py
            for @search-paths -> $path {
                my $full-path = join('/', $path, "$module-name.py");

                next unless $full-path.IO.e;

                my $input = $full-path.IO.slurp;
                $p5 = $.compiler.compile(
                    $input,
                    :module(True),
                    :embedded($import-sha1-hash),
                    :import-names($node.import-names.names.map({ $_.name })),
                );

                last if $p5;
            }

            %!modules{$import-sha1-hash} = $p5 if $p5;
        }

        # we found not python module, fallback to perl module loading for our StdLib shims
        # if even this fails we, unlike python, abort on runtime
        if not $p5 {
            return sprintf(
                q|Python2::Internals::import_module($stack, [{ name => '%s', name_as => '%s', functions => [qw/%s/] }])|,
                $node.name, $node.name, $node.import-names.names.map({ $_.name }).join(' ')
            );
        }
    }

    multi method e(Python2::AST::Node::Statement::Import $node) {
        my Str $import-definition;

        for $node.modules.values -> $module {
            $import-definition ~= sprintf('{ name => \'%s\', name_as => \'%s\' }, ',
                $module<name>, $module<name-as>
            );
        }

        return sprintf('Python2::Internals::import_module($stack, [%s])', $import-definition);
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
            $p5 ~= @positional-arguments.map({
                $_.splat
                    ?? sprintf('(Python2::Internals::unsplat(${ %s }))', $.e($_))
                    !! '${' ~ $.e($_) ~ '}'
            }).join(', ');

            $p5 ~= ','; # to accomodate a possible named argument hashref
        }

        # named arguments get passed as a hashref to the perl method. this is allways passed as the
        # last argument and will be pop()'d before processing any other arguments.
        $p5 ~= 'bless({' ~ @named-arguments.map({ $.e($_.name) ~ ' => ' ~ $.e($_.value) }).join(',') ~ '}, "Python2::NamedArgumentsHash")';

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
        my Str $p5 = $node.values.map({ '${' ~ $.e($_) ~ '}' }).join(',');

        return sprintf('Python2::Internals::py2print(%s, {})', $p5);
    }

    multi method e(Python2::AST::Node::Statement::Del $node) {
        return sprintf('Python2::Internals::delvar($stack, \'%s\')', $node.name.name);
    }

    multi method e(Python2::AST::Node::Statement::Assert $node) {
        my Str $assertion-error = sprintf("Python2::Type::Exception->new('AssertionError', %s)",
            $node.message
                ?? $.e($node.message)
                !! ''
        );

        return sprintf('if ( not ${ %s }->__is_py_true__ ) { die %s; }',
            $.e($node.assertion),
            $assertion-error
        );
    }

    multi method e(Python2::AST::Node::Statement::Break $node) {
        return 'last;'
    }

    multi method e(Python2::AST::Node::Statement::Raise $node) {
        return $node.message
            ?? sprintf('Python2::Internals::raise(${ %s }, ${ %s })', $.e($node.exception), $.e($node.message))
            !! sprintf('Python2::Internals::raise(${ %s })', $.e($node.exception));
    }

    multi method e(Python2::AST::Node::Statement::VariableAssignment $node) {
        # see AST::Node::Power
        for $node.targets.values -> $target is rw {
            Python2::ParseFail.new(:pos($node.start-position), :what("Expected name")).throw()
                unless ($target.atom.expression ~~ Python2::AST::Node::Name);

            $target.must-resolve = False;
            $target.atom.recurse = False;   # if it's a variable assignment we
                                            # don't recurse upwards on the stack
        }

        # simple '1:1' assignment
        if ($node.targets.elems == 1) {
            $node.targets[0].assignment = $node.expression;

            return ((not $node.name-filter) or $node.name-filter.grep($node.targets[0].atom.expression.name))
                ??  $.e($node.targets[0])
                !!  '';
        }

        else {
            my Str $p5;

            # assign our (potential) iterable to $i
            $p5 ~= sprintf('{ my $i = %s;', $.e($node.expression));

            # die if the object cannot provide a length
            $p5 ~= sprintf(q|die Python2::Type::Exception->new('TypeError', 'Expected iterable, got ' . $$i->__type__) unless $$i->can('__len__');|);

            # die if the elements in the object don't match the amount of targets
            $p5 ~= sprintf(q|die Python2::Type::Exception->new('ValueError', 'too many values to unpack') unless ${$$i->__len__}->__tonative__ == %i;|, $node.targets.elems);

            my Int $i = 0;
            for $node.targets.values -> $target {
                if (not $node.name-filter or $node.name-filter.grep($target.atom.expression.name)) {
                    $p5 ~= sprintf(q|${%s} = ${ $$i->__getitem__(Python2::Type::Scalar::Num->new(%i)) };|, $.e($target), $i);
                }

                $i++;
            }

            return $p5 ~ '}';
        }


    }

    multi method e(Python2::AST::Node::Statement::ArithmeticAssignment $node) {
        my $operator = $node.operator.chop; # grammar ensures only valid operators pass thru here

        return sprintf(q|${%s} = ${ Python2::Internals::arithmetic(${ %s }, ${ %s }, '%s') }|,
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

        $p5 ~= sprintf('{ my $i = ${ %s };', $.e($node.iterable));

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
                $p5 ~= sprintf('Python2::Internals::setvar($stack, %s, $var->[%i]);', $.e($name), $index++);
            }

            $p5 ~= sprintf('%s', $.e($node.block));

            $p5 ~= q:to/END/;
                    };

                    if (($@) and ($@ eq 'StopIteration')) { last; } elsif ($@) { die $@; }
                }
                END
        }
        else {
            # single name, raw values from a list/tuple
            $p5 ~= 'foreach my $var ($i->ELEMENTS) {';
            $p5 ~= sprintf('Python2::Internals::setvar($stack, %s, $var);', $.e($node.names[0]));
            $p5 ~= sprintf('%s }', $.e($node.block));
        }

        return $p5 ~ ' } ';
    }


    multi method e(Python2::AST::Node::Statement::LoopWhile $node) {
        my Str $p5 = sprintf('while (1) { last unless ${ %s }->__tonative__; %s; }', $.e($node.test), $.e($node.block));

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::Pass $node) { return ''; }

    multi method e(Python2::AST::Node::Statement::Continue $node) { return 'next'; }

    multi method e(Python2::AST::Node::ListComprehension $node) {
        my Str $p5;

        $p5 ~= sprintf('sub { my $i = ${ %s };', $.e($node.iterable));
        $p5 ~= 'my $r = Python2::Type::List->new();';

        $p5 ~= 'die Python2::Type::Exception->new("TypeError", "expected iterable but got " . $i->__type__) unless ($i->__type__ =~ m/^list|tuple$/);';

        $p5 ~= 'foreach my $var ($i->ELEMENTS) {';
        $p5 ~= sprintf('Python2::Internals::setvar($stack, %s, $var);', $.e($node.name));

        $p5 ~= sprintf('next unless ${ %s }->__tonative__;', $.e($node.condition))
            if ($node.condition);

        $p5 ~= sprintf('$r->__iadd__(${ %s });', $.e($node.test));
        $p5 ~= '}';

        return $p5 ~ 'return \$r; }->()';
    }

    multi method e(Python2::AST::Node::Statement::TryExcept $node) {
        my Str $p5 = sprintf('eval { %s }; if ($@) { my $e = $@; sub { %s die $@; }->()};',
            $.e($node.try-block),
            $node.except-blocks.values.map({ $.e($_) }).join(' '),
        );

        $p5 ~= sprintf('{ %s }', $.e($node.finally-block)) if $node.finally-block;

        return $p5;
    }

    multi method e(Python2::AST::Node::ExceptionClause $node) {
        return $node.exception
            ??  $node.name
                    # exception with type filter and name assignment
                    ??  sprintf(q|if ($e eq '%s') { Python2::Internals::setvar($stack, '%s', $e); %s; return; }|,
                            $node.exception.name,
                            $node.name.name,
                            $.e($node.block)
                        )

                    # exception with type filter only
                    !!  sprintf(q|if ($e eq '%s') { %s; return; }|, $node.exception.name, $.e($node.block))

            # generic 'except:'
            !! $.e($node.block) ~ ' return;';
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

        $p5 ~= sprintf('if ( ${ %s }->__is_py_true__ ) { %s }', $.e($node.test), $.e($node.block));

        for $node.elifs -> $elif {
            $p5 ~= $.e($elif);
        }

        $p5 ~= sprintf('else { %s }', $.e($node.else)) if $node.else;

        return $p5;
    }

    # TODO we don't implement all of with yet, no calls to __exit__
    # TODO this is 'good enough' for our fileIO use case since we close the FH on scope
    # TODO exit anyway.
    multi method e(Python2::AST::Node::Statement::With $node) {
        my Str $p5 = qq|\n# line 999 "___position_{$node.start-position}_{$node.block.start-position}___"\n|;

        # self-contained block to ensoure $p does not conflict
        $p5 ~= '{';

        # the object with references (with <object> as <variable>)
        $p5 ~= sprintf('my $o = %s;', $.e($node.test));

        # call __enter__ which must return the variable to be assigned
        $p5 ~= q|my $p = $$o->__enter__($stack, bless({}, 'Python2::NamedArgumentsHash'));|;

        # assign to <variable>
        $p5 ~= sprintf('Python2::Internals::setvar($stack, %s, $$p);', $.e($node.name));

        # our code block
        $p5 ~= $.e($node.block);

        # TODO - we don't implement python's arguments to __exit__
        $p5 ~= q|$$o->__exit__($stack, Python2::Type::Scalar::None->new(), Python2::Type::Scalar::None->new(), Python2::Type::Scalar::None->new(), bless({}, 'Python2::NamedArgumentsHash'));|;

        # end of self-contained block to ensoure $p does not conflict
        $p5 ~= '}';

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::ElIf $node) {
        return sprintf('elsif (${ %s }->__is_py_true__) { %s }', $.e($node.test), $.e($node.block));
    }

    multi method e(Python2::AST::Node::Statement::Test::Comparison $node) {
        if ($node.right) {
            my $left    = $node.comparison-operator eq '__contains__' ?? $node.right !! $node.left;
            my $right   = $node.comparison-operator eq '__contains__' ?? $node.left  !! $node.right;

            return $node.negate
                ??  sprintf('\Python2::Type::Scalar::Bool->new(not ${ ${%s}->%s(${%s}) }->__is_py_true__)',
                        $.e($left),
                        $node.comparison-operator,
                        $.e($right),
                    )
                !!  sprintf('${%s}->%s(${%s})',
                        $.e($left),
                        $node.comparison-operator,
                        $.e($right),
                    );
        } else {
            return $.e($node.left);
        }
    }

    multi method e(Python2::AST::Node::Test::Logical $node) {
        return $.e($node.values[0]) unless $node.condition;

        if ($node.condition.condition eq 'not') {
            # not always returns a bool
            return sprintf('\Python2::Type::Scalar::Bool->new(not ${%s}->__is_py_true__)', $.e($node.values[0]));
        }
        elsif ($node.condition.condition eq 'or') {
            # or returns the first true value or, if all are false, the last value
            my Str $p5;
            $p5 ~= 'sub { my $t;';

            for $node.values -> $value {
                $p5 ~= sprintf('$t = %s; return $t if $$t->__is_py_true__;', $.e($value));
            }

            # if we didn't return before the all values are false - return the last one
            $p5 ~= 'return $t;';

            $p5 ~= '}->()';

            return $p5;
        }
        else {
            # and returns the first false value or, of all are true, the last value
            my Str $p5;
            $p5 ~= 'sub { my $t;';

            for $node.values -> $value {
                $p5 ~= sprintf('$t = %s; return $t unless $$t->__is_py_true__;', $.e($value));
            }

            # if we didn't return before the all values are true - return the last one
            $p5 ~= 'return $t;';

            $p5 ~= '}->()';

            return $p5;
        }
    }

    multi method e(Python2::AST::Node::Statement::FunctionDefinition $node) {
        # *args must always be the last parameter, keep track if we have already seen it
        # so we can abort if anything comes after.
        my Bool $splat_seen = False;

        my Str $perl5_class_name = 'Python2::Type::Class::class_' ~ sha1-hex($node.start-position ~ $.e($node.block));

        my Str $block;

        # local stack frame for this function
        $block ~= 'my $self = shift; my $stack = $self->{stack}; $stack->clear;';

        # argument definition containing, if present, default vaules
        my Str $argument-definition = '';
        for $node.argument-list -> $argument {
            Python2::ParseFail.new(:pos($argument.start-position)).throw()
                if $splat_seen;

            $argument-definition  ~= sprintf('[ \'%s\', %s, %i ],',
                $argument.name.name,
                $argument.default-value ?? $.e($argument.default-value) !! 'undef',
                $argument.splat ?? 1 !! 0,
            );

            $splat_seen = True if $argument.splat;
        }

        # call Python2::Python2::Internals::getopt() to parse our arguments
        $block ~= sprintf('Python2::Internals::getopt($stack, \'%s\', [%s], @_);',
            $node.name.name.subst("'", "\\'", :g),
            $argument-definition
        );

        # the actual function body
        $block ~= $.e($node.block);

        # if the function body contains a return statement it will execute before this
        $block   ~= 'return \Python2::Type::Scalar::None->new();';

        # the call to shift to get rid of $self which we don't need in this case.
        %!modules{$perl5_class_name} = sprintf(
            'package %s { use base qw/ Python2::Type::Function /; use Python2; sub __name__ { %s }; sub __call__ { %s } }',
            $perl5_class_name,
            $.e($node.name),
            $block,
        );

        return sprintf('Python2::Internals::setvar($stack, %s, %s->new($stack));',
            $.e($node.name),
            $perl5_class_name,
        );
    }

    multi method e(Python2::AST::Node::LambdaDefinition $node) {
        my Str $perl5_class_name = 'Python2::Type::Class::class_' ~ sha1-hex($node.start-position ~ $.e($node.block));

        my Str $block;

        # local stack frame for this lambda
        $block ~= 'my $self = shift; my $stack = $self->{stack}; $stack->clear;';

        # get arguments
        for $node.argument-list -> $argument {
            $block ~= sprintf('Python2::Internals::setvar($stack, \'%s\', shift);', $argument.name.name);
        }

        # the actual function body
        $block ~= sprintf('my $retvar = %s; return $retvar;', $.e($node.block));

        %!modules{$perl5_class_name} = sprintf(
            'package %s { use base qw/ Python2::Type::Function /; use Python2; sub __name__ { "lambda"; }; sub __call__ { %s } }',
            $perl5_class_name,
            $block,
        );

        return sprintf('\%s->new($stack)', $perl5_class_name);
    }

    multi method e(Python2::AST::Node::Statement::ClassDefinition $node) {
        my Str $perl5_class_name = 'Python2::Type::Class::class_' ~ sha1-hex($node.start-position ~ $.e($node.block));
        my Str $preamble = 'use Python2; use Python2::Type::Object;';

        # everything in %!modules will be placed at the beginning of the code
        %!modules{$perl5_class_name} = sprintf(
            # we inject the base class at runtime by setting up @Package::ISA
            'package %s { %s sub __build__ { my $self = $_[0]; $self->SUPER::__build__(); my $stack = $self->{stack}; %s; return $self; } }',
            $perl5_class_name,
            $preamble,
            $.e($node.block)
        );

        my Str $p5;

        if $node.base-class {
            $p5 ~= sprintf(q|my $base_class = Python2::Internals::getvar($stack, 1, '%s'); $%s::ISA[0] = ref($$base_class);|, $node.base-class.name, $perl5_class_name);
        }
        else {
            $p5 ~= sprintf(q|$%s::ISA[0] = 'Python2::Type::Object';|, $perl5_class_name);
        };


        $p5 ~= sprintf('Python2::Internals::setvar($stack, \'%s\', %s->new());',
            $node.name.name.subst("'", "\\'", :g),
            $perl5_class_name,
        );

        return $p5;
    }


    # Expressions
    multi method e(Python2::AST::Node::Expression::Container $node) {
        # grammar ensures we only get valid operators here
        my %operator-method-map =
            '|'     => '__or__',
            '&'     => '__and__',
            '^'     => '__xor__',
            '<<'    => '__lshift__',
            '>>'    => '__rshift__',
            ;

        my $p5;

        my @expressions = $node.expressions.clone;
        my @operators   = $node.operators.clone;

        # initial left element
        my $left-element = @expressions.shift;

        my $operator;
        my $right-element;

        $p5 ~= sprintf('sub { my $left = %s;', $.e($left-element));

        # as long as we have operators remaining there must be more expressions
        while @operators.elems > 0 {
            $operator       = @operators.shift;
            $right-element  = @expressions.shift;

            $p5 ~= sprintf(
                '$left = $$left->%s(${ %s });',
                %operator-method-map{$operator},
                $.e($right-element)
            );
        }

        $p5 ~= 'return $left; }->()';

        return $p5;
    }

    multi method e(Python2::AST::Node::Power $node) {
        my @elements = ($node.atom, $node.trailers).flat;

        my Str $p5 = 'my $p = undef; shift;';

        # single atom
        if (@elements.elems == 1) {
            $p5 ~= sprintf('$p = %s;', $.e(@elements[0]));

            $p5 ~= sprintf(q|$$p // die Python2::Type::Exception->new("NameError", "name '%s' is not defined");|, @elements[0].expression.name)
                if ($node.must-resolve and @elements[0].expression ~~ Python2::AST::Node::Name);

            return $node.assignment
                ?? sprintf('${ sub{ %s; return $p; }->() } = ${ %s }', $p5, $.e($node.assignment))
                !! sprintf('sub{ %s; return $p; }->()', $p5);
        }


        # chained expressions
        while @elements.elems > 0 {
            my $current-element = @elements.shift;
            my $next-element = @elements.first;

            # function call
            if $current-element ~~ Python2::AST::Node::Atom and $next-element ~~ Python2::AST::Node::ArgumentList {
                    my $argument-list = @elements.shift;

                    $p5 ~= sprintf('$p = %s;', $.e($current-element));

                    $p5 ~= sprintf(q|$$p // die Python2::Type::Exception->new("NameError", "name '%s' is not defined");|, $current-element.expression.name)
                        if ($current-element.expression ~~ Python2::AST::Node::Name) and $node.must-resolve;

                    $p5 ~= sprintf('$p = $$p->__call__(%s);', $.e($argument-list));
            }

            # method call
            elsif $current-element ~~ Python2::AST::Node::Name and $next-element ~~ Python2::AST::Node::ArgumentList {
                my $argument-list = @elements.shift;

                # check if the object has a p5-style method
                $p5 ~= sprintf(q|if ($$p->can('%s')) {|, $current-element.name);

                # if yes, call it
                $p5 ~= sprintf(q|$p = $$p->%s(%s);|, $current-element.name, $.e($argument-list));

                $p5 ~= '} else {';

                # keep track of the object so we can pass it as self
                $p5 ~= 'my $o = $p;';

                # no p5-style method, give the object a chance to return a Function object via the __getattr__ fallback
                $p5 ~= sprintf(q|$p = ${$p}->__getattr__(Python2::Type::Scalar::String->new('%s'), {});|, $current-element.name);

                # die if even the fallback did not return anything
                $p5 ~= sprintf(q|$$p // die Python2::Type::Exception->new('AttributeError', ref($$p) . " instance has no attribute '%s'");|, $current-element.name);

                # got a python-style method, call it
                $p5 ~= sprintf(q|$p = $$p->__call__($$o, %s);|, $.e($argument-list));

                $p5 ~= '}';
            }

            # subscript
            elsif $current-element ~~ Python2::AST::Node::Subscript {
                if $current-element.target {
                    die("Variable Assignment to Slice not supported") if $node.assignment;

                    $p5 ~= sprintf('$p = ${$p}->__getslice__(%s, {});', $.e($current-element)) # array slice
                }
                else {
                    if ($node.assignment and @elements.elems == 0) {
                        $p5 ~= sprintf('$p = ${$p}->__setitem__(%s, ${ %s }, {});', $.e($current-element), $.e($node.assignment));
                    }
                    else {
                        $p5 ~= sprintf('$p = ${$p}->__getitem__(%s, {});', $.e($current-element));

                        $p5 ~= sprintf(q|$$p // die Python2::Type::Exception->new('KeyError', 'No element with key ' . %s);|, $.e($current-element))
                            if $node.must-resolve;
                    }
                }
            }

            # attribute access
            elsif $current-element ~~ Python2::AST::Node::Name {
                if ($node.assignment and @elements.elems == 0) {
                    $p5 ~= sprintf(q|$p = ${$p}->__setattr__(Python2::Type::Scalar::String->new(%s), ${ %s }, {});|, $.e($current-element), $.e($node.assignment));
                }
                else {
                    $p5 ~= sprintf(q|$p = ${$p}->__getattr__(Python2::Type::Scalar::String->new(%s), {});|, $.e($current-element));

                    $p5 ~= sprintf(q|$$p // die Python2::Type::Exception->new("AttributeError", "no attribute '%s'");|, $current-element.name)
                        if ($node.must-resolve or @elements.elems > 0) and ($current-element ~~ Python2::AST::Node::Name);
                }
            }

            # function call to returned element ("x[0]()" and similar)
            elsif $current-element ~~ Python2::AST::Node::ArgumentList {
                $p5 ~= sprintf(q|$p = $$p->__call__(%s);|, $.e($current-element));
            }

            # single name
            else {
                #die;
                $p5 ~= sprintf('$p = %s;', $.e($current-element));
                $p5 ~= sprintf(q|$$p // die Python2::Type::Exception->new("NameError", "name '%s' is not defined");|, $current-element.expression.name)
                    if ($node.must-resolve or @elements.elems > 0) and ($current-element.expression ~~ Python2::AST::Node::Name);
            }
        }

        return sprintf('sub{ %s; return $p; }->()', $p5);
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
                q|$left = Python2::Internals::arithmetic(${ $left }, ${ %s }, '%s');|,
                $right-element,
                $.e($operation)
            );
        }

        $p5 ~= 'return $left; }->()';

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
        return sprintf('\Python2::Type::Scalar::Num->new(%s)', $node.value);
    }

    multi method e(Python2::AST::Node::Expression::Literal::Float $node) {
        return sprintf('\Python2::Type::Scalar::Num->new(%s)', $node.value)
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
        # TODO python allowes the creation of single-element tuples by adding a comma "(1,)"

        # empty tuple "x = ()" becomes an empty tuple
        if ($node.tests.elems == 0) {
            return '\Python2::Type::Tuple->new()';
        }

        # tuple with multiple values "x = (1, 2, 3)" - regular tuple
        elsif $node.tests.elems > 1 {
            return sprintf('\Python2::Type::Tuple->new(%s)',
                $node.tests.map({ '${' ~ self.e($_) ~ '}' }).join(', ')
            );
        }

        elsif $node.tests.elems == 1 {
            # if a tuple would only contain a single element python disregards the parenthesis
            return sprintf('%s', $.e($node.tests[0]));
        }

        else {
            die("Invalid TestList"); # should be unreachable
        }
    }

    # dictionary handling
    multi method e(Python2::AST::Node::Expression::DictionaryDefinition $node) {
        return sprintf('\Python2::Type::Dict->new(%s)',
            $node.entries.map({
                '${' ~ $.e($_.key) ~ '} => ${' ~ $.e($_.value) ~ '}'
            }).join(', ')
       );
    }

    # set handling
    multi method e(Python2::AST::Node::Expression::SetDefinition $node) {
        return sprintf('\Python2::Type::Set->new(%s)',
            $node.entries.map({
                '${' ~ $.e($_) ~ '}'
            }).join(', ')
       );
    }

    multi method e(Python2::AST::Node::Block $node) {
        return sprintf('%s', $node.statements.map({
            self.e($_)
        }).join(''));
    }


    # Fallback
    multi method e($node) {
        die("Perl 5 backed for node not implemented: $node");
    }
}
