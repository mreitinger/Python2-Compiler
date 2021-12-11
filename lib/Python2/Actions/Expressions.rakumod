use Python2::AST;
use Data::Dump;

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

    multi method expression ($/ where $/<list-definition>) {
        $/.make($/<list-definition>.made);
    }

    multi method expression ($/ where $/<dictionary-definition>) {
        $/.make($/<dictionary-definition>.made);
    }

    multi method expression($/ where $<function-call>) {
        $/.make($<function-call>.made);
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

    multi method iterable ($/ where $/<list-definition>) {
        $/.make($/<list-definition>.made);
    }

    multi method iterable ($/ where $/<variable-access>) {
        $/.make($/<variable-access>.made);
    }

    multi method iterable ($/) {
        die("iterable not implemented for " ~ Dump($/))
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


    # list handling
    multi method list-definition($/) {
        $/.make(Python2::AST::Node::Expression::ListDefinition.new(
            expressions => $/<expression-list>.made.expressions
        ));
    }

    multi method expression-list($/) {
        my $expression-list = Python2::AST::Node::Expression::ExpressionList.new();

        for $/<expression> -> $expression {
            $expression-list.expressions.push($expression.made);
        }

        $/.make($expression-list);
    }


    # dictionary handling
    multi method dictionary-definition($/) {
        use Data::Dump;

        # get every dictionary entry in the list. we just bypass the intermediate
        # dictionary-entry-list that we just use for the grammar so far.
        my %dictionary-entries;

        for $/<dictionary-entry-list><dictionary-entry> -> $entry {
            my $key = $entry<dictionary-key>.Str;
            my $expression = $entry<expression>.made;

            %dictionary-entries{$key} = $expression;
        }

        $/.make(Python2::AST::Node::Expression::DictionaryDefinition.new(
            entries => %dictionary-entries,
        ));
    }

    multi method function-call($/) {
        my @arguments;
        for $/<expression> -> $argument {
            @arguments.push($argument.made);
        }

        $/.make(Python2::AST::Node::Expression::FunctionCall.new(
            function-name => $/<function-name>.Str,
            arguments     => @arguments,
        ));
    }


    # fallback
    multi method expression ($/) {
        die("Action for expression not implemented: " ~ $/)
    }
}