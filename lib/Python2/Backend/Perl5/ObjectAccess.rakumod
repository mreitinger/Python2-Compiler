use Python2::AST;

role Python2::Backend::Perl5::ObjectAccess {
    multi method e(Python2::AST::Node::Expression::ObjectAccess $node) {
        # wrap in a sub{} so we can keep track of the object when performing method calls
        #
        return sprintf('sub { my $p = getvar($stack, %s); %s }->()',
            $.e($node.name),
            $node.operations.map({ self.e($_) }).join(''),
        );
    }

    multi method e(Python2::AST::Node::Expression::MethodCall $node) {
        # TODO unkown method check
        return sprintf('$p = $p->{stack}->[ITEMS]->{%s}->([$p, %s]);',
            $.e($node.name),
            $node.arguments.map({ self.e($_) }).join(', '),
        );
    }

    multi method e(Python2::AST::Node::Expression::InstanceVariableAccess $node) {
        return sprintf('$p = getvar($p->{stack}, %s);', $.e($node.name));
    }
}