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

            # handle argument lists/subscripts/etc
            for $_.trailers { $.t($_) }

            next unless $_.trailers.elems == 0;

            if ($_.atom.expression ~~ Python2::AST::Node::Expression::Literal) {
                $_ = $_.atom.expression;
            }
        }
    }

    multi method t (Python2::AST::Node::ArgumentList $node) {
        for $node.arguments { $.t($_) }
    }

    multi method t (Python2::AST::Node::Test $node) {
        $.t($node.left);
        $.t($node.right) if $node.right;
    }

    multi method t (Python2::AST::Node::Test::Logical $node) {
        $.t($node.left);
        $.t($node.right) if $node.right;

        # left/right is always a comparison or logical test. strip it out if it has no
        # condition

        for ($node.left, $node.right) {
            if ($_ ~~ Python2::AST::Node::Statement::Test::Comparison) {
                $_ = $_.left if not $_.comparison-operator;
            }
            elsif ($_ ~~ Python2::AST::Node::Test::Logical) {
                $_ = $_.left if not $_.condition;
            }
        }
    }

    multi method t (Python2::AST::Node::Statement::Test::Comparison $node) {
        $.t($node.left);
        $.t($node.right) if $node.right;
    }

    multi method t (Python2::AST::Node::Statement::VariableAssignment $node) {
        # expression is always a test
        $.t($node.expression);

        # optimize out the test if it has no condition
        next if $node.expression.condition;
        $node.expression = $node.expression.left;
    }

    multi method t ($node) {}
}