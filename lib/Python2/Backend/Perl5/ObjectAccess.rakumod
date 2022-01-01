use Python2::AST;

role Python2::Backend::Perl5::ObjectAccess {
    multi method e(Python2::AST::Node::Expression::ObjectAccess $node) {
        # wrap in a sub{} so we can keep track of the object when performing method calls
        #
        my $p5 = 'sub { my $p = Python2::getvar($stack, \'' ~ $node.object-name ~ '\'); ';

        for $node.operations -> $operation {
            $p5 ~= $.e($operation);
        }

        $p5 ~= '}->() ';

        return $p5;
    }

    multi method e(Python2::AST::Node::Expression::MethodCall $node) {
        my $p5 = '$p = Python2::call($p->{stack}, \'' ~ $node.method-name ~ '\', [$p, ';

        for $node.arguments -> $argument {
            $p5 ~= $.e($argument);
            $p5 ~= ','; # TODO trailing slash
        }

        $p5 ~=   ']); ';

        return $p5;
    }

    multi method e(Python2::AST::Node::Expression::InstanceVariableAccess $node) {
        return '$p = Python2::getvar($p->{stack}, \'' ~ $node.variable-name ~ '\');'
    }
}