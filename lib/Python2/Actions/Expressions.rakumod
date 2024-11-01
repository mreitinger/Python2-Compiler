use Python2::AST;

role Python2::Actions::Expressions {
    # token expression {
    #     <xor-expresion> [ <.ws> '|' <.ws> <xor-expression> ]*
    # }

    # token xor-expression {
    #     <and-expresion> [ <.ws> '^' <.ws> <and-expression> ]*
    # }

    # token and-expression {
    #     <shift-expresion> [ <.ws> '&' <.ws> <shift-expression> ]*
    # }

    # token shift-expression {
    #     <arithmetic-expression-low-precedence> [ <.ws> <shift-expression-operator> <.ws> <arithmetic-expression-low-precedence> ]
    # }

    # token shift-expression-operator {
    #     | '<<'
    #     | '>>'
    # }

    # top level 'expression'
    method expression ($/) {
        if $<or-expression-operator> {
            make Python2::AST::Node::Expression::Container.new(
                start-position  => $/.from,
                end-position    => $/.to,
                expressions     => $/<xor-expression>.map({ $_.made }),
                operators       => $/<or-expression-operator>.map({ $_.Str }),
            );
        }
        else {
            make $/<xor-expression>[0].made;
        }
    }

    method xor-expression ($/) {
        if $<xor-expression-operator> {
            make Python2::AST::Node::Expression::Container.new(
                start-position  => $/.from,
                end-position    => $/.to,
                expressions     => $/<and-expression>.map({ $_.made }),
                operators       => $/<xor-expression-operator>.map({ $_.Str }),
            );
        }
        else {
            make $/<and-expression>[0].made;
        }
    }


    method and-expression ($/) {
        if $<and-expression-operator> {
            make Python2::AST::Node::Expression::Container.new(
                start-position  => $/.from,
                end-position    => $/.to,
                expressions     => $/<shift-expression>.map({ $_.made }),
                operators       => $/<and-expression-operator>.map({ $_.Str }),
            );
        }
        else {
            make $/<shift-expression>[0].made;
        }
    }

    method shift-expression ($/) {
        if $/<shift-expression-operator> {
            make Python2::AST::Node::Expression::Container.new(
                start-position  => $/.from,
                end-position    => $/.to,
                expressions     => $/<arithmetic-expression-low-precedence>.map({ $_.made }),
                operators       => $/<shift-expression-operator>.map({ $_.Str }),
            );
        }
        else {
            make $/<arithmetic-expression-low-precedence>[0].made;
        }
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

    method locals ($/) {
        $/.make(Python2::AST::Node::Locals.new(
            start-position  => $/.from,
            end-position    => $/.to,
        ))
    }

    method dotted-name ($/) {
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
        if $/<trailer> {
            my $atom = $/<atom>.made;
            for $/<trailer> {
                my $trailer = $_.made;
                given $trailer {
                    when Python2::AST::Node::Name {
                        $atom = Python2::AST::Node::PropertyAccess.new(
                            start-position  => $/.from,
                            end-position    => $/.to,
                            atom            => $atom,
                            property        => $trailer,
                        )
                    }
                    when Python2::AST::Node::Subscript {
                        $atom = Python2::AST::Node::SubscriptAccess.new(
                            start-position  => $/.from,
                            end-position    => $/.to,
                            atom            => $atom,
                            subscript       => $trailer,
                        )
                    }
                    when Python2::AST::Node::ArgumentList {
                        given $atom {
                            when Python2::AST::Node::PropertyAccess {
                                $atom = Python2::AST::Node::Call::Method.new(
                                    start-position  => $/.from,
                                    end-position    => $/.to,
                                    atom            => $atom.atom,
                                    name            => $atom.property,
                                    arglist         => $trailer,
                                )
                            }
                            when Python2::AST::Node::Atom {
                                $atom = Python2::AST::Node::Call::Name.new(
                                    start-position  => $/.from,
                                    end-position    => $/.to,
                                    name            => $atom,
                                    arglist         => $trailer,
                                )
                            }
                            default {
                                $atom = Python2::AST::Node::Call.new(
                                    start-position  => $/.from,
                                    end-position    => $/.to,
                                    atom            => $atom,
                                    arglist         => $trailer,
                                )
                            }
                        }
                    }
                    default {
                        die "Unknown trailer: $_.gist()";
                    }
                }
            }
            make $atom;
        }
        else {
            make $/<atom>.made
        }
    }

    multi method atom ($/ where $/<dictionary-entry-list>) {
        $/.make(Python2::AST::Node::Atom.new(
            start-position  => $/.from,
            end-position    => $/.to,
            expression => $/<dictionary-entry-list>.made
        ))
    }

    multi method atom ($/) {
        make $/<name>
            ?? Python2::AST::Node::Atom.new(
                start-position  => $/.from,
                end-position    => $/.to,
                expression => $/.values[0].made
            )
            !! $/.values[0].made
    }

    # literals
    multi method string ($/ where $/<single-quoted-string>) {
        my $string-prefix = $/<string-prefix>:exists ?? $/<string-prefix> !! '';

        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value     => $/<single-quoted-string>.<string-literal-single-quoted>.Str.subst("\\\n", "", :g),
            raw       => $string-prefix eq 'r',
            unicode   => $string-prefix eq 'u',
        ));
    }

    multi method string ($/ where $/<double-quoted-string>) {
        my $string-prefix = $/<string-prefix>:exists ?? $/<string-prefix> !! '';

        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value           => $/<double-quoted-string>.<string-literal-double-quoted>.Str.subst("\\\n", "", :g),
            raw             => $string-prefix eq 'r',
            unicode         => $string-prefix eq 'u',
        ));
    }

    multi method string ($/ where $/<triple-single-quoted-string>) {
        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value           => $/<triple-single-quoted-string>.<string-literal-triple-single-quoted>.Str.subst("\\\n", "", :g),
            raw             => False,
            unicode         => False,
        ));
    }

    multi method string ($/ where $/<triple-double-quoted-string>) {
        $/.make(Python2::AST::Node::Expression::Literal::String.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value           => $/<triple-double-quoted-string>.<string-literal-triple-double-quoted>.Str.subst("\\\n", "", :g),
            raw             => False,
            unicode         => False,
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
            arithmetic-operator => $/<high-precedence-operator>.Str,
        ));
    }

    method arithmetic-operator-low-precedence ($/) {
        $/.make(Python2::AST::Node::Expression::ArithmeticOperator.new(
            start-position  => $/.from,
            end-position    => $/.to,
            arithmetic-operator => $/<low-precedence-operator>.Str,
        ));
    }

    # arithmetic operations
    method arithmetic-expression-low-precedence ($/) {
        if $/<arithmetic-operator-low-precedence> {
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

            make Python2::AST::Node::Expression::ArithmeticExpression.new(
                start-position  => $/.from,
                end-position    => $/.to,
                operations => @operations,
            );
        }
        else {
            make $/<arithmetic-expression-high-precedence>[0].made;
        }
    }

    method arithmetic-expression-high-precedence ($/) {
        if $/<arithmetic-operator-high-precedence> {
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

            make Python2::AST::Node::Expression::ArithmeticExpression.new(
                start-position  => $/.from,
                end-position    => $/.to,
                operations => @operations,
            );
        }
        else {
            make $/<power>[0].made;
        }
    }

    # subscript
    multi method subscript ($/ where $/<test>) {
        $/.make(Python2::AST::Node::Subscript.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value           => $/<test>.made,
            target          => Nil,
        ))
    }

    multi method subscript ($/ where $/<full-slice>) {
        $/.make(Python2::AST::Node::Subscript.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value           => $/<full-slice><test>[0].made,
            target          => $/<full-slice><test>[1].made,
        ))
    }

    multi method subscript ($/ where $/<start-slice>) {
        $/.make(Python2::AST::Node::Subscript.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value           => Python2::AST::Node::Expression::Literal::Integer.new(value => 0),
            target          => $/<start-slice><test>.made,
        ))
    }

    multi method subscript ($/ where $/<end-slice>) {
        $/.make(Python2::AST::Node::Subscript.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value           => $/<end-slice><test>.made,
            target          => Python2::AST::Node::Expression::Literal::Integer.new(value => -1),
        ))
    }

    method literal ($/) {
        $/.make($/.values[0].made);
    }

    method expression-list($/) {
        my $expression-list = Python2::AST::Node::Expression::ExpressionList.new(
            start-position  => $/.from,
            end-position    => $/.to,
        );

        for $/<expression> -> $expression {
            $expression-list.expressions.push($expression.made);
        }

        $/.make($expression-list);
    }

    method test-list($/) {
        my $test-list = Python2::AST::Node::Expression::TestList.new(
            start-position  => $/.from,
            end-position    => $/.to,
            trailing-comma => $/<trailing-comma>.so
        );

        for $/<test> -> $test {
            $test-list.tests.push($test.made);
        }

        $/.make($test-list);
    }

    method extended-test-list($/) {
        my $test-list = Python2::AST::Node::Expression::TestList.new(
            start-position  => $/.from,
            end-position    => $/.to,
            trailing-comma => $/<trailing-comma>.so
        );

        for $/<test> -> $test {
            $test-list.tests.push($test.made);
        }

        $/.make($test-list);
    }


    method list-comprehension($/) {
        $/.make(Python2::AST::Node::ListComprehension.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name>.made,
            iterable        => $/<test>[1].made,
            test            => $/<test>[0].made,
            condition       => $/<test>[2] ?? $/<test>[2].made !! Nil,
        ));
    }


    # dictionary handling
    method dictionary-entry-list($/) {
        # get every dictionary entry in the list. we just bypass the intermediate
        # dictionary-entry-list that we just use for the grammar so far.
        my @dictionary-entries;

        for $/<dictionary-entry> -> $entry {
            my $key         = $entry<test>[0].made;
            my $expression  = $entry<test>[1].made;

            @dictionary-entries.append(Pair.new($key, $expression));
        }

        $/.make(Python2::AST::Node::Expression::DictionaryDefinition.new(
            start-position  => $/.from,
            end-position    => $/.to,
            entries => @dictionary-entries,
        ));
    }

    method dict-comprehension($/) {
        $/.make(Python2::AST::Node::DictComprehension.new(
            start-position  => $/.from,
            end-position    => $/.to,
            names           => $/<name>.map(*.made),
            iterable        => $/<iterable>.made,
            key             => $/<key>.made,
            value           => $/<value>.made,
            condition       => $/<condition> ?? $/<condition>.made !! Nil,
        ));
    }

    # set handling
    method set-entry-list($/) {
        # get every set entry in the list. we just bypass the intermediate
        # set-entry-list that we just use for the grammar so far.
        my @set-entries;

        for $/<set-entry> -> $entry {
            my $expression  = $entry<test>.made;

            @set-entries.append($expression);
        }

        $/.make(Python2::AST::Node::Expression::SetDefinition.new(
            start-position  => $/.from,
            end-position    => $/.to,
            entries         => @set-entries,
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
            start-position   => $/.from,
            end-position     => $/.to,
            arguments        => $/<argument>.map({ $_.made }),
            flattened-nameds => $<kwargs>.made,
        ));
    }

    multi method argument($/ where $/<test>) {
        $/.make(Python2::AST::Node::Argument.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name> ?? $/<name>.made !! Nil,
            value           => $/<test>.made,
            splat           => $/<splat> ?? True !! False,
        ));
    }

    multi method argument($/ where $/<list-comprehension>) {
        $/.make(Python2::AST::Node::Argument.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name> ?? $/<name>.made !! Nil,
            value           => $/<list-comprehension>.made,
            splat           => $/<splat> ?? True !! False,
        ));
    }

    multi method test($/ where $/<lambda-definition>) {
        $/.make(Python2::AST::Node::Test.new(
            start-position  => $/.from,
            end-position    => $/.to,
            left        => $<lambda-definition>.made,
            right       => Nil,
            condition   => Nil,
        ));
    }

    multi method test($/) {
        if $/<condition> {
            make Python2::AST::Node::Test.new(
                start-position  => $/.from,
                end-position    => $/.to,
                left            => $<left>.made,
                right           => $<right>     ?? $<right>.made       !! Nil,
                condition       => $<condition> ?? $<condition>.made !! Nil,
            );
        }
        else {
            make $/<left>.made;
        }
    }

    method or_test($/) {
        if $<and_test> > 1 {
            make Python2::AST::Node::Test::Logical.new(
                start-position  => $/.from,
                end-position    => $/.to,
                values          => $<and_test>.map({ $_.made }),

                # if we have more than one value set the condition - otherwise set it to Nil
                # so we can optimize it out later
                condition       => $<and_test>[1]
                    ?? Python2::AST::Node::Test::LogicalCondition.new(condition => 'or')
                    !! Nil,
            );
        }
        else {
            make $<and_test>[0].made;
        }
    }

    method and_test($/) {
        if $/<not_test> > 1 {
            make Python2::AST::Node::Test::Logical.new(
                start-position  => $/.from,
                end-position    => $/.to,
                values          => $<not_test>.map({ $_.made }),

                # if we have more than one value set the condition - otherwise set it to Nil
                # so we can optimize it out later
                condition       => $<not_test>[1]
                    ?? Python2::AST::Node::Test::LogicalCondition.new(condition => 'and')
                    !! Nil,
            );
        }
        else {
            make $/<not_test>[0].made;
        }
    }

    multi method not_test($/ where $/<comparison>) {
        $/.make($/<comparison>.made);
    }

    multi method not_test($/ where $/<not_test>) {
        $/.make(Python2::AST::Node::Test::Logical.new(
            start-position  => $/.from,
            end-position    => $/.to,
            values          => ( $<not_test>.made ),
            condition       => Python2::AST::Node::Test::LogicalCondition.new(condition => 'not'),
        ));
    }

    method comparison ($/) {
        if $/<comparison-operator> {
            make Python2::AST::Node::Statement::Test::Comparison.new(
                start-position  	=> $/.from,
                end-position    	=> $/.to,

                operators => $<comparison-operator>.map(*.Str),
                operands  => $<expression>.map(*.made),
            );
        }
        else {
            make $/<expression>[0].made;
        }
    }

    method function-definition-argument-list($/) {
        my Python2::AST::Node::Statement::FunctionDefinition::Argument @argument-list;

        for $/<function-definition-argument> -> $argument {
            @argument-list.push($argument.made);
        }
        @argument-list.push: Python2::AST::Node::Statement::FunctionDefinition::Argument.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $<varargs>.made,
            splat           => 1,
        ) if $<varargs>;
        @argument-list.push: Python2::AST::Node::Statement::FunctionDefinition::Argument.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $<kwargs>.made,
            splat           => 2,
        ) if $<kwargs>;

        $/.make(@argument-list);
    }

    method function-definition-argument($/) {
        $/.make(Python2::AST::Node::Statement::FunctionDefinition::Argument.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name>.made,
            default-value   => $/<test> ?? $/<test>.made !! Nil,
            splat           => 0,
        ));
    }
}
