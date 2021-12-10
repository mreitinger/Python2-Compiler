use Python2::AST;
use Data::Dump;

class Python2::Backend::Perl5 {
    has Str $!o = "use v5.26.0; use strict;\n\n"; # Generated Perl 5 code

    # root node: iteral over all statements and create perl code for them
    multi method e(Python2::AST::Node::Root $node) {
        for ($node.nodes) {
            $!o ~= $.e($_);
        }

        return $!o;
    }

    # Statements
    multi method e(Python2::AST::Node::Statement::Print $node) {
        return 'say ' ~ $.e($node.expression) ~ ";";
    }

    # Expressions
    multi method e(Python2::AST::Node::Expression::Literal::String $node) {
        return "'" ~ $node.value ~ "'";
    }

    multi method e(Python2::AST::Node::Expression::Literal::Integer $node) {
        return $node.value;
    }

    # Fallback
    multi method e($node) {
        die("Perl 5 backed for node not implemented: " ~ Dump($node));
    }
}