use Python2::AST;

class Python2::Optimizer {
    multi method t (Python2::AST::Node::Expression::Container $node is rw) {
        for $node.expressions -> $expression is rw {
            $.t($expression);
        }

        if $node.expressions.elems == 1 {
            $node = $node.expressions[0];
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
        # Descend to all our children
        for $node.values -> $value is rw {
            $.t($value);
        }

        # If we don't have a condition strip out the test
        $node = $node.values[0] if not $node.condition;
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