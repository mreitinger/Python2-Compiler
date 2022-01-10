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
        my $p5 = sprintf('$p = call($p->{stack}, %s, [$p, ', $.e($node.name));

        for $node.arguments -> $argument {
            $p5 ~= $.e($argument);
            $p5 ~= ','; # TODO trailing slash
        }

        $p5 ~=   ']); ';

        return $p5;
    }

    multi method e(Python2::AST::Node::Expression::InstanceVariableAccess $node) {
        return sprintf('$p = getvar($p->{stack}, %s);', $.e($node.name));
    }
}