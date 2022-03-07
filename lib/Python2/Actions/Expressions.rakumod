use Python2::AST;
use Data::Dump;

class Python2::Actions::Expressions {
    # top level 'expression'
    method expression ($/) {
        $/.make(Python2::AST::Node::Expression::Container.new(
            expression  => $/<arithmetic-expression-low-precedence>.made,
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

    method lambda-definition ($/) {
        $/.make(Python2::AST::Node::LambdaDefinition.new(
            argument-list   => $/<function-definition-argument-list>.made,
            block           => $/<test>.made,
        ));
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

    method arithmetic-operator-high-precedence ($/) {
        $/.make(Python2::AST::Node::Expression::ArithmeticOperator.new(
            arithmetic-operator => $/.Str.trim, #TODO not sure why whitespace gets captured here?
        ));
    }

    method arithmetic-operator-low-precedence ($/) {
        $/.make(Python2::AST::Node::Expression::ArithmeticOperator.new(
            arithmetic-operator => $/.Str.trim, #TODO not sure why whitespace gets captured here?
        ));
    }

    # arithmetic operations
    method arithmetic-expression-low-precedence ($/) {
        # a list of 'operations' to be performed in order from 'left' to 'right'
        # format: number, operator, number, operator, number, operator, number, ...
        my @operations;

        # the the first (left-most) number
        @operations.push($/<arithmetic-expression-high-precedence>.shift.made);

        #for every remaining number
        while ($/<arithmetic-expression-high-precedence>.elems) {
            # get the next operator in line
            push(@operations, $/<arithmetic-operator-low-precedence>.shift.made);

            # and the next number
            push(@operations, $/<arithmetic-expression-high-precedence>.shift.made);
        }

        $/.make(Python2::AST::Node::Expression::ArithmeticExpression.new(
            operations => @operations,
        ));
    }

    method arithmetic-expression-high-precedence ($/) {
        # a list of 'operations' to be performed in order from 'left' to 'right'
        # format: number, operator, number, operator, number, operator, number, ...
        my @operations;

        # the the first (left-most) number
        @operations.push($/<power>.shift.made);

        #for every remaining number
        while ($/<power>.elems) {
            # get the next operator in line
            push(@operations, $/<arithmetic-operator-high-precedence>.shift.made);

            # and the next number
            push(@operations, $/<power>.shift.made);
        }

        $/.make(Python2::AST::Node::Expression::ArithmeticExpression.new(
            operations => @operations,
        ));
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

    method expression-list($/) {
        my $expression-list = Python2::AST::Node::Expression::ExpressionList.new();

        for $/<expression> -> $expression {
            $expression-list.expressions.push($expression.made);
        }

        $/.make($expression-list);
    }

    method test-list($/) {
        my $test-list = Python2::AST::Node::Expression::TestList.new();

        for $/<test> -> $test {
            $test-list.tests.push($test.made);
        }

        $/.make($test-list);
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

    multi method object-access-operation ($/ where $/<instance-variable-access>) {
        $/.make($/<instance-variable-access>.made);
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