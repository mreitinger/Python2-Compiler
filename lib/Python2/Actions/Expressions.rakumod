use Python2::AST;

class Python2::Actions::Expressions {
    # top level 'expression'
    multi method expression ($/ where $/<literal>) {
        $/.make($/<literal>.made);
    }

    multi method literal ($/ where $/<string>) {
        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            value => $/<string>.Str,
        ))
    }

    multi method expression ($/) {
        die("Action for expression not implemented: " ~ $/)
    }
}