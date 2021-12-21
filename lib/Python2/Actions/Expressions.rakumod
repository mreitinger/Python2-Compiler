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

    multi method literal ($/ where $/<number>) {
        $/.make($/<number>.made)
    }

    multi method number ($/ where $/<integer>) {
        $/.make(Python2::AST::Node::Expression::Literal::Integer.new(
            value => $/<integer>.Int,
        ))
    }

    multi method number ($/ where $/<float>) {
        $/.make(Python2::AST::Node::Expression::Literal::Float.new(
            value => $/<float>.Num,
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

    method arithmetic-operator ($/) {
        $/.make(Python2::AST::Node::Expression::ArithmeticOperator.new(
            arithmetic-operator => $/.Str,
        ))
    }

    multi method operand ($/ where $/<number>) {
        $/.make($/<number>.made);
    }

    multi method operand ($/ where $/<variable-access>) {
        $/.make($/<variable-access>.made);
    }

    # arithmetic operations
    multi method arithmetic-operation ($/) {
        # a list of 'operations' to be performed in order from 'left' to 'right'
        # format: number, operator, number, operator, number, operator, number, ...
        my @operations;

        # the the first (left-most) number
        @operations.push($/<operand>.shift.made);

        # for every remaining number
        while ($/<operand>.elems) {
            # get the next operator in line
            push(@operations, $/<arithmetic-operator>.shift.made);

            # and the next number
            push(@operations, $/<operand>.shift.made);
        }

        $/.make(Python2::AST::Node::Expression::ArithmeticOperation.new(
            operations => @operations,
        ))
    }

    # variable access
    multi method variable-access ($/ where $/<variable-name>) {
        $/.make(Python2::AST::Node::Expression::VariableAccess.new(
            variable-name => $/<variable-name>.Str,
        ))
    }

    multi method variable-access ($/ where $/<instance-variable-access>) {
        $/.make($/<instance-variable-access>.made);
    }

    # instance variable access
    multi method instance-variable-access ($/) {
        $/.make(Python2::AST::Node::Expression::InstanceVariableAccess.new(
            object-name   => $/<variable-name>[0].Str,
            variable-name => $/<variable-name>[1].Str,
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

        for $/<function-call-argument-list>.made -> $argument {
            @arguments.push($argument);
        }

        $/.make(Python2::AST::Node::Expression::FunctionCall.new(
            function-name => $/<function-name>.Str,
            arguments     => @arguments,
        ));
    }

    # TODO we should do a a AST intermediate here to provide more data for further optimization
    method function-call-argument-list($/) {
        my Python2::AST::Node @argument-list;

        for $/<expression> -> $argument {
            @argument-list.push($argument.made);
        }

        $/.make(@argument-list);
    }


    # fallback
    multi method expression ($/) {
        die("Action for expression not implemented: " ~ $/)
    }
}