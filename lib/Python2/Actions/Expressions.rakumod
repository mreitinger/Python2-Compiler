use Python2::AST;
use Data::Dump;

class Python2::Actions::Expressions {
    # top level 'expression'
    method expression ($/) {
        $/.make(Python2::AST::Node::Expression::Container.new(
            expression  => $/<arithmetic-operation>.made,
        ));
    }

    method trailer ($/) {
        $/.make($/.values[0].made);
    }

    method name ($/) {
        $/.make(Python2::AST::Node::Name.new(
            name => $/.Str
        ))
    }

    # this does not yet implement power (as in **) but is here for future expansion and since
    # we need it to match atom/trailers.
    method power ($/) {
        $/.make(Python2::AST::Node::Power.new(
            atom        => $/<atom>.made,
            trailers    => $/<trailer>.map({ $_.made })
        ))
    }

    multi method atom ($/ where $/<dictionary-entry-list>) {
        $/.make(Python2::AST::Node::Atom.new(
            expression => $/<dictionary-entry-list>.made
        ))
    }

    multi method atom ($/) {
        $/.make(Python2::AST::Node::Atom.new(
            expression => $/.values[0].made
        ))
    }

    # literals
    method string ($/) {
        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            value => $/<string-literal>.subst('\"', '"', :g).subst("\\'", "'", :g),
        ))
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

    method operand ($/) {
        $/.make($/.values[0].made);
    }

    # arithmetic operations
    method arithmetic-operation ($/) {
        # a list of 'operations' to be performed in order from 'left' to 'right'
        # format: number, operator, number, operator, number, operator, number, ...
        my @operations;

        # the the first (left-most) number
        @operations.push($/<power>.shift.made);

         #for every remaining number
        while ($/<power>.elems) {
            # get the next operator in line
            push(@operations, $/<arithmetic-operator>.shift.made);

            # and the next number
            push(@operations, $/<power>.shift.made);
        }

        $/.make(Python2::AST::Node::Expression::ArithmeticOperation.new(
            operations => @operations,
        ))
    }

    # variable access
    multi method variable-access ($/ where $/<name>) {
        $/.make(Python2::AST::Node::Expression::VariableAccess.new(
            name => $/<name>.made,
        ))
    }

    multi method variable-access ($/ where $/<object-access>) {
        $/.make($/<object-access>.made);
    }


    # subscript
    method subscript ($/) {
        $/.make(Python2::AST::Node::Subscript.new(
            value => $/<literal>.made, #TODO we only support literals at this time
        ))
    }

    method literal ($/) {
        $/.make($/.values[0].made);
    }


    # list handling
    method list-definition($/) {
        $/.make(Python2::AST::Node::Expression::ListDefinition.new(
            expressions => $/<expression-list>.made.expressions
        ));
    }

    method expression-list($/) {
        my $expression-list = Python2::AST::Node::Expression::ExpressionList.new();

        for $/<expression> -> $expression {
            $expression-list.expressions.push($expression.made);
        }

        $/.make($expression-list);
    }


    # dictionary handling
    method dictionary-entry-list($/) {
        # get every dictionary entry in the list. we just bypass the intermediate
        # dictionary-entry-list that we just use for the grammar so far.
        my %dictionary-entries;

        for $/<dictionary-entry> -> $entry {
            my $key = $entry<dictionary-key>.Str;
            my $expression = $entry<expression>.made;

            %dictionary-entries{$key} = $expression;
        }

        $/.make(Python2::AST::Node::Expression::DictionaryDefinition.new(
            entries => %dictionary-entries,
        ));
    }

    method object-access($/) {
        my Python2::AST::Node @operations;

        for ($/<object-access-operation>) -> $operation {
            push(@operations, $operation.made);
        }

        $/.make(Python2::AST::Node::Expression::ObjectAccess.new(
            name        => $/<name>.made,
            operations  => @operations,
        ));
    }

    multi method object-access-operation ($/ where $/<method-call>) {
        $/.make($/<method-call>.made);
    }

    multi method object-access-operation ($/ where $/<instance-variable-access>) {
        $/.make($/<instance-variable-access>.made);
    }

    multi method method-call($/) {
        my @arguments;

        for $/<function-call-argument-list>.made -> $argument {
            @arguments.push($argument);
        }

        $/.make(Python2::AST::Node::Expression::MethodCall.new(
            name        => $/<name>.made,
            arguments   => @arguments,
        ));
    }

    # instance variable access
    method instance-variable-access ($/) {
        $/.make(Python2::AST::Node::Expression::InstanceVariableAccess.new(
            name => $/<name>.made,
        ))
    }

    method argument-list($/) {
        $/.make(Python2::AST::Node::ArgumentList.new(
            arguments => $/<test>.map({ $_.made })
        ));
    }
}