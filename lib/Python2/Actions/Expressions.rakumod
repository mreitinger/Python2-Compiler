use Python2::AST;
use Data::Dump;

class Python2::Actions::Expressions {
    # top level 'expression'
    method expression ($/) {
        $/.make(Python2::AST::Node::Expression::Container.new(
            start-position  => $/.from,
            end-position    => $/.to,
            expression      => $/<arithmetic-expression-low-precedence>.made,
        ));
    }

    method trailer ($/) {
        $/.make($/.values[0].made);
    }

    method name ($/) {
        $/.make(Python2::AST::Node::Name.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/.Str,
        ))
    }

    method lambda-definition ($/) {
        $/.make(Python2::AST::Node::LambdaDefinition.new(
            start-position  => $/.from,
            end-position    => $/.to,
            argument-list   => $/<function-definition-argument-list>.made,
            block           => $/<test>.made,
        ));
    }

    # this does not yet implement power (as in **) but is here for future expansion and since
    # we need it to match atom/trailers.
    method power ($/) {
        $/.make(Python2::AST::Node::Power.new(
            start-position  => $/.from,
            end-position    => $/.to,
            atom            => $/<atom>.made,
            trailers        => $/<trailer>.map({ $_.made })
        ))
    }

    multi method atom ($/ where $/<dictionary-entry-list>) {
        $/.make(Python2::AST::Node::Atom.new(
            start-position  => $/.from,
            end-position    => $/.to,
            expression => $/<dictionary-entry-list>.made
        ))
    }

    multi method atom ($/) {
        $/.make(Python2::AST::Node::Atom.new(
            start-position  => $/.from,
            end-position    => $/.to,
            expression => $/.values[0].made
        ))
    }

    # literals
    multi method string ($/ where $/<single-quoted-string>) {
        my $string-prefix = $/<string-prefix>:exists ?? $/<string-prefix> !! '';

        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value => $/<single-quoted-string>.<string-literal-single-quoted>.Str,
            raw   => $string-prefix eq 'r',
        ));
    }

    multi method string ($/ where $/<double-quoted-string>) {
        my $string-prefix = $/<string-prefix>:exists ?? $/<string-prefix> !! '';

        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value => $/<double-quoted-string>.<string-literal-double-quoted>.Str,
            raw   => $string-prefix eq 'r'
        ));
    }

    multi method string ($/ where $/<triple-single-quoted-string>) {
        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value => $/<triple-single-quoted-string>.<string-literal-triple-single-quoted>.Str,
            raw   => False,
        ));
    }

    multi method string ($/ where $/<triple-double-quoted-string>) {
        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value => $/<triple-double-quoted-string>.<string-literal-triple-double-quoted>.Str,
            raw   => False,
        ));
    }

    multi method number ($/ where $/<integer>) {
        $/.make(Python2::AST::Node::Expression::Literal::Integer.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value => $/<integer>.Int,
        ));
    }

    multi method number ($/ where $/<float>) {
        $/.make(Python2::AST::Node::Expression::Literal::Float.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value => $/<float>.Num,
        ))
    }

    method arithmetic-operator-high-precedence ($/) {
        $/.make(Python2::AST::Node::Expression::ArithmeticOperator.new(
            start-position  => $/.from,
            end-position    => $/.to,
            arithmetic-operator => $/.Str.trim, #TODO not sure why whitespace gets captured here?
        ));
    }

    method arithmetic-operator-low-precedence ($/) {
        $/.make(Python2::AST::Node::Expression::ArithmeticOperator.new(
            start-position  => $/.from,
            end-position    => $/.to,
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
            start-position  => $/.from,
            end-position    => $/.to,
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
            start-position  => $/.from,
            end-position    => $/.to,
            operations => @operations,
        ));
    }

    # subscript
    method subscript ($/) {
        $/.make(Python2::AST::Node::Subscript.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value   => $/<test>[0].made,
            target  => $/<test>[1]:exists ?? $/<test>[1].made !! Nil,
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
        my @dictionary-entries;

        for $/<dictionary-entry> -> $entry {
            my $key = $entry<test>.made;
            my $expression = $entry<expression>.made;

            @dictionary-entries.append(Pair.new($key, $expression));
        }

        $/.make(Python2::AST::Node::Expression::DictionaryDefinition.new(
            start-position  => $/.from,
            end-position    => $/.to,
            entries => @dictionary-entries,
        ));
    }

    multi method object-access-operation ($/ where $/<instance-variable-access>) {
        $/.make($/<instance-variable-access>.made);
    }

    # instance variable access
    method instance-variable-access ($/) {
        $/.make(Python2::AST::Node::Expression::InstanceVariableAccess.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name => $/<name>.made,
        ))
    }

    method argument-list($/) {
        $/.make(Python2::AST::Node::ArgumentList.new(
            start-position  => $/.from,
            end-position    => $/.to,
            arguments => $/<argument>.map({ $_.made })
        ));
    }

    method argument($/) {
        $/.make(Python2::AST::Node::Argument.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name    => $/<name> ?? $/<name>.made !! Nil,
            value   => $/<test>.made,
        ));
    }
}
