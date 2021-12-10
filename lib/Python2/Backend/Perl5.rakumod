use Python2::AST;
use Data::Dump;

class Python2::Backend::Perl5 {
    has Str $!o =
        "use v5.26.0;\n" ~
        "use strict;\n" ~
        "use lib qw( p5lib );\n" ~
        "use Python2;\n\n" ~
        'my $stack = {};' ~ "\n\n";
    ;

    # root node: iteral over all statements and create perl code for them
    multi method e(Python2::AST::Node::Root $node) {
        for ($node.nodes) {
            $!o ~= $.e($_);
        }

        return $!o;
    }

    # Statements
    multi method e(Python2::AST::Node::Statement::Print $node) {
        return 'Python2::py2print(' ~ $.e($node.expression) ~ ");\n";
    }

    multi method e(Python2::AST::Node::Statement::VariableAssignment $node) {
        return 'Python2::setvar($stack, \'' ~ $node.variable-name ~ "', " ~ $.e($node.expression) ~ ");";
    }


    # Expressions
    # TODO ArithmeticOperation's should probably(?) operate on Literal::Integer
    multi method e(Python2::AST::Node::Expression::ArithmeticOperation $node) {
        return $node.left ~ $node.operator ~ $node.right;
    }

    multi method e(Python2::AST::Node::Expression::Literal::String $node) {
        return "'" ~ $node.value ~ "'";
    }

    multi method e(Python2::AST::Node::Expression::Literal::Integer $node) {
        return $node.value;
    }

    multi method e(Python2::AST::Node::Expression::VariableAccess $node) {
        return 'Python2::getvar($stack, \'' ~ $node.variable-name ~ "')";
    }


    # list handling
    multi method e(Python2::AST::Node::Expression::ListDefinition $node) {
        my $p5 = '[';

        for $node.expressions -> $expression {
            $p5 ~= $.e($expression);
            $p5 ~= ','; # TODO trailing slash
        }

        $p5 ~= ']';

        return $p5;
    }


    # Fallback
    multi method e($node) {
        die("Perl 5 backed for node not implemented: " ~ Dump($node));
    }
}
