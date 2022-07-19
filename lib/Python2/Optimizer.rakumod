use Python2::AST;

class Python2::Optimizer {
    multi method t (Python2::AST::Node::Expression::Container $node is rw) {
        $.t($node.expression);

        # usually this is an ArithmeticExpression but the optimizer might have reduced it to a
        # Literal already
        return unless $node.expression ~~ Python2::AST::Node::Expression::ArithmeticExpression;

        if ($node.expression.operations.elems == 1) {
            $node.expression = $node.expression.operations[0];
        }
    }

    multi method t (Python2::AST::Node::Expression::ArithmeticExpression $node is rw) {
        # strip intermediate nodes if it's just a literal in the end
        for $node.operations {
            if ($_ ~~ Python2::AST::Node::Power) {
                # handle the atom part
                $.t($_.atom);

                # handle argument lists/subscripts/etc
                for $_.trailers { $.t($_) }

                # if there a trailers we don't optimize anything
                next unless $_.trailers.elems == 0;

                # if the atom is just a literal in the end skip it
                if ($_.atom.expression ~~ Python2::AST::Node::Expression::Literal) {
                    $_ = $_.atom.expression;
                }
            }
            else {
                $.t($_);
            }
        }

        if ($node.operations.elems == 1 and $node.operations[0] ~~ Python2::AST::Node::Expression::Literal) {
            $node = $node.operations[0];
        }
    }

    multi method t (Python2::AST::Node::Test::Logical $node is rw) {
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

    multi method t (Python2::AST::Node::Statement::VariableAssignment $node is rw) {
        # expression is always a test
        $.t($node.expression);

        # optimize out the test if it has no condition
        next if $node.expression.condition;
        $node.expression = $node.expression.left;
    }

    # fallback: if we don't know better just optimize all attributes on the current
    # AST node.
    multi method t (Python2::AST::Node $node is rw) {
        for $node.^attributes -> $attribute {
            my $name = $attribute.name.subst(/^[\$|\@|\%]\!?/, '');

            if ($attribute.name ~~ /^^\$/) {
                next if $name eq 'start-position';
                next if $name eq 'end-position';
                $.t( $node."$name"() );
            }
            elsif ($attribute.name ~~ /^^\@/) {
                for $node."$name"() { $.t($_) }
            }
            elsif ($attribute.name ~~ /^^\%/) {
                for $node."$name"().kv { $.t($_) }
            }
            else {
                die("unsupported attribute type: {$attribute.name}");
            }
        }
    }

    # noop for literals - no 'is rw' since they are immutable
    multi method t ($node) {}

    # everything else needs to be handled above
    multi method t ($node is rw) {}
}