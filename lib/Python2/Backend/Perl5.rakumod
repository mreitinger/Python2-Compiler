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
        "use Python2;\n\n" ~
        'my $stack = [];' ~ "\n\n" ~
        'use constant { PARENT => 0, VARIABLES => 1, FUNCTIONS => 2, CLASSES => 3 };' ~ "\n\n";

    # we use an array instead of a hash for faster lookups.
    # Layout:
    #[
    #    $parent,    # reference to parent stack
    #    {},         # variables in our scope
    #    {},         # function definitions in our scope
    #    {},         # class definitions in our scope
    #]

    # root node: iteral over all statements and create perl code for them
    multi method e(Python2::AST::Node::Root $node) {
        for ($node.nodes) {
            $!o ~= $.e($_);
        }

        return $!o;
    }

    # Statements
    # statement 'container': if it's a statement append ; to make the perl parser happy
    multi method e(Python2::AST::Node::Statement $node) {
        return $.e($node.statement) ~ ";\n";
    }

    multi method e(Python2::AST::Node::Statement::Print $node) {
        return sprintf('Python2::py2print(%s)', $.e($node.value));
    }

    multi method e(Python2::AST::Node::Statement::VariableAssignment $node) {
        if ($node.list-or-dict-element) {
            return sprintf('Python2::setvar_e($stack, \'%s\', %s, %s)',
                $node.variable-name,
                $.e($node.list-or-dict-element),
                $.e($node.expression),
            );
        } else {
            return sprintf('Python2::setvar($stack, \'%s\', %s)',
                $node.variable-name,
                $.e($node.expression)
            );
        }
    }

    multi method e(Python2::AST::Node::Statement::Return $node) {
        return sprintf('return %s', $.e($node.value));
    }



    # loops
    multi method e(Python2::AST::Node::Statement::LoopFor $node) {
        return sprintf('foreach my $var (@{ %s->elements }) { Python2::setvar($stack, \'%s\', $var); %s }',
            $.e($node.iterable),
            $node.variable-name,
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

    multi method e(Python2::AST::Node::Statement::If $node) {
        my $p5 = sprintf('if (%s) { %s }', $.e($node.test), $.e($node.block));

        $p5 ~= sprintf('else { %s }', $.e($node.else)) if $node.else;

        return $p5;
    }

    multi method e(Python2::AST::Node::Statement::Test::Expression $node) {
        return $.e($node.expression);
    }

    multi method e(Python2::AST::Node::Statement::Test::Comparison $node) {
        return sprintf('Python2::compare(%s, %s, \'%s\')',
            $.e($node.left),
            $.e($node.right),
            $node.comparison-operator
        );
    }

    multi method e(Python2::AST::Node::Statement::FunctionDefinition $node) {
        my $p5 = sprintf('Python2::register_function($stack, \'%s\', sub {', $node.function-name);

        $p5 ~= 'my $arguments = shift;' ~ "\n";
        $p5 ~= 'my $stack = [ $stack ];' ~ "\n";

        for $node.argument-list -> $argument {
            $p5 ~= sprintf('Python2::setvar($stack, \'%s\', shift @$arguments);', $argument);
        }

        $p5   ~= $.e($node.block);
        $p5   ~= "});"
    }

    multi method e(Python2::AST::Node::Statement::ClassDefinition $node) {
        return sprintf('Python2::create_class($stack, \'%s\', sub { my $stack = shift; %s })',
            $node.class-name,
            $.e($node.block)
        );
    }

    # Expressions
    multi method e(Python2::AST::Node::Expression::Container $node) {
        return $.e($node.expression);
    }

    # TODO ArithmeticOperation's should probably(?) operate on Literal::Integer
    multi method e(Python2::AST::Node::Expression::ArithmeticOperation $node) {
        my $p5;

        for $node.operations -> $operation {
            $p5 ~= $.e($operation);
        }

        return $p5;
    }

    multi method e(Python2::AST::Node::Expression::ArithmeticOperator $node) {
        return $node.arithmetic-operator;
    }

    multi method e(Python2::AST::Node::Expression::Literal::String $node) {
        return "'" ~ $node.value.subst("'", "\\'", :g) ~ "'";
    }

    multi method e(Python2::AST::Node::Expression::Literal::Integer $node) {
        return $node.value;
    }

    multi method e(Python2::AST::Node::Expression::Literal::Float $node) {
        return $node.value;
    }

    multi method e(Python2::AST::Node::Expression::VariableAccess $node) {
        return 'Python2::getvar($stack, \'' ~ $node.variable-name ~ "')";
    }

    multi method e(Python2::AST::Node::Statement::InstanceVariableAssignment $node) {
        my Str $p5;
        if ($node.list-or-dict-element) {
            # assuming object.array[0]
            # fetch stack for object
            return sprintf('Python2::setvar_e(%s->{stack}, \'%s\', %s, %s)',
                $.e($node.object-access),
                $node.target-variable.variable-name.Str,
                $.e($node.list-or-dict-element),
                $.e($node.expression)
            );
        } else {
            # assuming object.item
            # fetch stack for object
            return sprintf('Python2::setvar(%s->{stack}, \'%s\', %s)',
                $.e($node.object-access),
                $node.target-variable.variable-name.Str,
                $.e($node.expression),
            );
        }
    }

    multi method e(Python2::AST::Node::Expression::DictionaryAccess $node) {
        return sprintf('Python2::getvar($stack, \'%s\')->element(%s)',
            $node.dictionary-name,
            $node.key
        );
    }

    # function calls
    multi method e(Python2::AST::Node::Expression::FunctionCall $node) {
        return sprintf('Python2::call($stack, \'%s\', [ %s ])',
            $node.function-name,
            $node.arguments.map({ self.e($_) }).join(', ')
        );
    }


    # list handling
    multi method e(Python2::AST::Node::Expression::ListDefinition $node) {
        return sprintf('Python2::Type::List->new(%s)',
            $node.expressions.map({ self.e($_ )}).join(', ')
        );
    }


    # dictionary handling
    multi method e(Python2::AST::Node::Expression::DictionaryDefinition $node) {
        return sprintf('Python2::Type::Dict->new(%s)',
            $node.entries.map({ $_.key ~ '=>' ~ $.e($_.value) }).join(', ')
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
