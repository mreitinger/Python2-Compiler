use Data::Dump;
use Python2::AST;

class Python2::Optimizer {
    multi method t (Python2::AST::Node::Root $node) {
        for $node.nodes -> $node {
            $.t($node);
        }
    }

    multi method t (Python2::AST::Node::Statement $node) {
        $.t($node.statement);
    }

    multi method t (Python2::AST::Node::Expression::Container $node) {
        $.t($node.expression);

        # always ArithmeticOperation. If it's just a single element we don't need the
        # intermidiate nodes
        if ($node.expression.operations.elems == 1) {
            $node.expression = $node.expression.operations[0];
        }
    }

    multi method t (Python2::AST::Node::Expression::ArithmeticOperation $node) {
        # strip intermidiate nodes if it's just a literal in the end
        for $node.operations {
            next unless $_ ~~ Python2::AST::Node::Power;
            next unless $_.trailers.elems == 0;

            if ($_.atom.expression ~~ Python2::AST::Node::Expression::Literal) {
                $_ = $_.atom.expression;
            }
        }
    }

    multi method t ($node) {}
}