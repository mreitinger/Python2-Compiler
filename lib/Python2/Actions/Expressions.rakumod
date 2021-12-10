use Python2::AST;

class Python2::Actions::Expressions {
    # top level 'expression'
    multi method expression ($/ where $/<literal>) {
        $/.make($/<literal>.made);
    }

    multi method expression ($/ where $/<arithmetic-operation>) {
        $/.make($/<arithmetic-operation>.made);
    }

    multi method expression ($/ where $/<variable-access>) {
        $/.make($/<variable-access>.made);
    }

    # literals
    multi method literal ($/ where $/<string>) {
        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            value => $/<string>.Str,
        ))
    }

    multi method literal ($/ where $/<integer>) {
        $/.make(Python2::AST::Node::Expression::Literal::Integer.new(
            value => $/<integer>.Int,
        ))
    }


    # arithmetic operations
    multi method arithmetic-operation ($/) {
        $/.make(Python2::AST::Node::Expression::ArithmeticOperation.new(
            left        => $/<integer>[0].Int,
            right       => $/<integer>[1].Int,
            operator    => $/<arithmetic-operator>.Str,
        ))
    }


    # variable access
    multi method variable-access ($/) {
        $/.make(Python2::AST::Node::Expression::VariableAccess.new(
            variable-name => $/<variable-name>.Str,
        ))
    }

    # fallback
    multi method expression ($/) {
        die("Action for expression not implemented: " ~ $/)
    }
}