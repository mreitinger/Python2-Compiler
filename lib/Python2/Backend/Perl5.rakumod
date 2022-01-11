use Python2::AST;
use Data::Dump;

use Python2::Backend::Perl5::ObjectAccess;

class Python2::Backend::Perl5
    does Python2::Backend::Perl5::ObjectAccess
{
    has Str $!o =
        "use v5.26.0;\n" ~
        "use strict;\n" ~
        "use lib qw( p5lib );\n" ~
        "use Data::Dumper;\n" ~
        "use Python2;\n\n" ~
        'my $stack = [ $builtins ];' ~ "\n\n" ~
        'use constant { PARENT => 0, ITEMS => 1 };' ~ "\n\n";

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

        return $!o;
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
        return sprintf('%s', $node.arguments.map({ '${' ~ $.e($_) ~ '}' }).join(', '));
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
        return sprintf('return ${%s}', $.e($node.value));
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

    multi method e(Python2::AST::Node::Statement::Test::Expression $node) {
        die;
        return $.e($node.expression);
    }

    multi method e(Python2::AST::Node::Statement::Test::Comparison $node) {
        if ($node.right) { #tmp hack until we get this right
            return sprintf('compare(${%s}, ${%s}, \'%s\')',
                $.e($node.left),
                $.e($node.right),
                $node.comparison-operator
            );
        } else {
            return $.e($node.left);
        }
    }

    multi method e(Python2::AST::Node::Statement::FunctionDefinition $node) {
        my $p5 = sprintf(
            'setvar($stack, \'%s\', sub {',
            $node.name.name.subst("'", "\\'", :g)
        );

        $p5 ~= 'my $arguments = shift;' ~ "\n";
        $p5 ~= 'my $stack = [$builtins];' ~ "\n";

        for $node.argument-list -> $argument {
            $p5 ~= sprintf('setvar($stack, \'%s\', shift @$arguments);', $argument);
        }

        $p5   ~= $.e($node.block);
        $p5   ~= "});"
    }

    multi method e(Python2::AST::Node::Statement::ClassDefinition $node) {
        return sprintf('create_class($stack, \'%s\', sub { my $stack = shift; %s })',
            $node.name.name.subst("'", "\\'", :g),
            $.e($node.block)
        );
    }

    # Expressions
    multi method e(Python2::AST::Node::Expression::Container $node) {
        return $.e($node.expression);
    }

    multi method e(Python2::AST::Node::Power $node) {
        my $p5 = 'sub {';
        $p5   ~= 'my $p2 = undef;';
        $p5   ~= sprintf('my $p = %s;', $.e($node.atom));

        my $prev;

        for $node.trailers -> $trailer {
            if ($trailer ~~ Python2::AST::Node::Name) {
                $p5 ~= sprintf('$p2 = $p; $p = getvar(${$p}->{stack}, %s);', $.e($trailer));
            }
            elsif ($trailer ~~ Python2::AST::Node::ArgumentList) {
                if ($prev ~~ Python2::AST::Node::Name) {
                    # the previous trailer was method name: pass the previous object to it
                    # so it ends up in 'self'
                    $p5 ~= sprintf('$p = \${$p}->([${$p2}, %s]);', $.e($trailer));
                } else {
                    $p5 ~= sprintf('$p = \${$p}->([%s]);', $.e($trailer));
                }
            }
            elsif ($trailer ~~ Python2::AST::Node::Subscript) {
                $p5 ~= sprintf('$p = ${$p}->element(${ %s });', $.e($trailer));
            }
            else {
                die("invalid trailer: $trailer");
            }

            $prev = $trailer;
        }

        $p5 ~= '}->()';

        return $p5;
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

    multi method e(Python2::AST::Node::Statement::InstanceVariableAssignment $node) {
        my Str $p5;
        if ($node.list-or-dict-element) {
            # assuming object.array[0]
            # fetch stack for object
            return sprintf('setvar_e(%s->{stack}, %s, %s, %s)',
                $.e($node.object-access),
                $.e($node.target-variable.name),
                $.e($node.list-or-dict-element),
                $.e($node.expression)
            );
        } else {
            # assuming object.item
            # fetch stack for object
            return sprintf('setvar(%s->{stack}, %s, %s)',
                $.e($node.object-access),
                $.e($node.target-variable.name),
                $.e($node.expression),
            );
        }
    }

    multi method e(Python2::AST::Node::Subscript $node) {
        return sprintf('%s', $.e($node.value));
    }

    # list handling
    multi method e(Python2::AST::Node::Expression::ExpressionList $node) {
        return sprintf('\Python2::Type::List->new(%s)',
            $node.expressions.map({ '${' ~ self.e($_ ) ~ '}' }).join(', ')
        );
    }


    # dictionary handling
    multi method e(Python2::AST::Node::Expression::DictionaryDefinition $node) {
        return sprintf('\Python2::Type::Dict->new(%s)',
            $node.entries.map({ $_.key ~ '=> ${' ~ $.e($_.value) ~ '}' }).join(', ')
        );
    }

    multi method e(Python2::AST::Node::Block $node) {
        return sprintf('{ %s }',  $node.statements.map({ self.e($_) }).join(''));
    }


    # Fallback
    multi method e($node) {
        die("Perl 5 backed for node not implemented: " ~ Dump($node));
    }
}
