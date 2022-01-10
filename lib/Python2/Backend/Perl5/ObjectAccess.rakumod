use Python2::AST;

role Python2::Backend::Perl5::ObjectAccess {
    multi method e(Python2::AST::Node::Expression::ObjectAccess $node) {
        # wrap in a sub{} so we can keep track of the object when performing method calls
        #
        my $p5 = sprintf('sub { my $p = getvar($stack, %s);', $.e($node.name));

        for $node.operations -> $operation {
            $p5 ~= $.e($operation);
        }

        $p5 ~= '}->() ';

        return $p5;
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