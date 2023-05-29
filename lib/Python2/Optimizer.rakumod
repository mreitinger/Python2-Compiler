use Python2::AST;

class Python2::Optimizer {
    # fallback: if we don't know better just optimize all attributes on the current
    # AST node.
    multi method t (Python2::AST::Node $node is rw) {
#        for $node.^attributes -> $attribute {
#            my $name = $attribute.name.subst(/^[\$|\@|\%]\!?/, '');
#
#            if ($attribute.name.starts-with('$')) {
#                next if $name eq 'start-position';
#                next if $name eq 'end-position';
#                my $child = $node."$name"();
#                $.t( $child ) if defined $child;
#            }
#            elsif ($attribute.name.starts-with('@')) {
#                for $node."$name"() { $.t($_) }
#            }
#            elsif ($attribute.name.starts-with('%')) {
#                for $node."$name"().kv { $.t($_) }
#            }
#            else {
#                die("unsupported attribute type: {$attribute.name}");
#            }
#        }
    }

    # noop for literals - no 'is rw' since they are immutable
    multi method t ($node) {}

    # everything else needs to be handled above
    multi method t ($node is rw) {}
}
