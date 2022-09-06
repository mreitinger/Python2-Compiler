use Python2::AST;
use Data::Dump;

class Python2::Actions::Statements {
    method statement ($/) {
        die("Statement Action expects exactly one child but we got { $/.values.elems }")
            unless $/.values.elems == 1;

        $/.make(Python2::AST::Node::Statement.new(
                start-position  => $/.from,
                end-position    => $/.to,
                statement       => $/.values[0].made,
        ));
    }

    method statement-p5import($/) {
        $/.make(Python2::AST::Node::Statement::P5Import.new(
            start-position  => $/.from,
            end-position    => $/.to,
            perl5-package-name  => $/<perl5-package-name>.Str,
            name                => $/<name>.Str
        ));
    }

    method statement-import($/) {
        $/.make(Python2::AST::Node::Statement::Import.new(
            start-position      => $/.from,
            end-position        => $/.to,
            name                => $/<name>.Str
        ));
    }

    method statement-from($/) {
        $/.make(Python2::AST::Node::Statement::FromImport.new(
            start-position      => $/.from,
            end-position        => $/.to,
            name                => $/<dotted-name>.Str,
            import-names        => $/<import-names>.made,
        ));
    }

    method import-names($/) {
        $/.make(Python2::AST::Node::Statement::ImportNames.new(
            start-position      => $/.from,
            end-position        => $/.to,
            names               => $/<name>.map({ $_.made }),
        ));
    }

    method statement-print($/) {
        $/.make(Python2::AST::Node::Statement::Print.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value => $/.values[0].made
        ));
    }

    method statement-del($/) {
        $/.make(Python2::AST::Node::Statement::Del.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name>.made
        ));
    }

    method statement-assert($/) {
        $/.make(Python2::AST::Node::Statement::Assert.new(
            start-position  => $/.from,
            end-position    => $/.to,
            assertion       => $/<test>[0].made,
            message         => $/<test>[1] ?? $/<test>[1].made !! Nil,
        ));
    }

    method statement-break($/) {
        $/.make(Python2::AST::Node::Statement::Break.new(
            start-position  => $/.from,
            end-position    => $/.to,
        ));
    }

    method statement-raise($/) {
        $/.make(Python2::AST::Node::Statement::Raise.new(
            value => $/.values[0].made
        ));
    }

    method variable-assignment($/) {
        $/.make(Python2::AST::Node::Statement::VariableAssignment.new(
            start-position  => $/.from,
            end-position    => $/.to,
            target      => $/<power>.made,
            expression  => $/<test>.made
        ));
    }

    method arithmetic-assignment($/) {
        $/.make(Python2::AST::Node::Statement::ArithmeticAssignment.new(
            start-position  => $/.from,
            end-position    => $/.to,
            target      => $/<power>.made,
            value       => $/<test>.made,
            operator    => $/<arithmetic-assignment-operator>.Str,
        ));
    }

    method statement-loop-for($/) {
        $/.make(Python2::AST::Node::Statement::LoopFor.new(
            start-position  => $/.from,
            end-position    => $/.to,
            names           => $/<name>.List.map({ $_.made }),
            iterable        => $/<expression>.made,
            block           => $/<block>.made,
        ));
    }

    method statement-loop-while($/) {
        $/.make(Python2::AST::Node::Statement::LoopWhile.new(
            start-position  => $/.from,
            end-position    => $/.to,
            test            => $/<test>.made,
            block           => $/<block>.made,
        ));
    }

    method statement-if($/) {
        $/.make(Python2::AST::Node::Statement::If.new(
            start-position  => $/.from,
            end-position    => $/.to,
            test            => $/<test>.made,
            block           => $/<block>[0].made,
            elifs           => $/<statement-elif>.List.map({ $_.made }),
            else            => $/<block>[1] ?? $/<block>[1].made !! Python2::AST::Node,
        ));
    }

    method statement-with($/) {
        $/.make(Python2::AST::Node::Statement::With.new(
            start-position  => $/.from,
            end-position    => $/.to,
            test            => $/<test>.made,
            block           => $/<block>.made,
            name            => $/<name>.made
        ));
    }

    method statement-elif($/) {
        $/.make(Python2::AST::Node::Statement::ElIf.new(
            start-position  => $/.from,
            end-position    => $/.to,
            test            => $/<test>.made,
            block           => $/<block>.made,
        ));
    }

    method statement-try-except($/) {
        $/.make(Python2::AST::Node::Statement::TryExcept.new(
            start-position  => $/.from,
            end-position    => $/.to,
            try-block       => $/<block>[0].made,
            except-block    => $/<block>[1].made,
            finally-block   => $/<block>[2] ?? $/<block>[2].made !! Python2::AST::Node,
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
        $/.make(Python2::AST::Node::Test.new(
            start-position  => $/.from,
            end-position    => $/.to,
            left            => $<or_test>[0].made,
            right           => $<test>          ?? $<test>.made       !! Nil,
            condition       => $<or_test>[1]    ?? $<or_test>[1].made !! Nil,
        ));
    }

    method or_test($/) {
        $/.make(Python2::AST::Node::Test::Logical.new(
            start-position  => $/.from,
            end-position    => $/.to,
            values          => $<and_test>.map({ $_.made }),

            # if we have more than one value set the condition - otherwise set it to Nil
            # so we can optimize it out later
            condition       => $<and_test>[1]
                ?? Python2::AST::Node::Test::LogicalCondition.new(condition => 'or')
                !! Nil,
        ));
    }

    method and_test($/) {
        $/.make(Python2::AST::Node::Test::Logical.new(
            start-position  => $/.from,
            end-position    => $/.to,
            values          => $<not_test>.map({ $_.made }),

            # if we have more than one value set the condition - otherwise set it to Nil
            # so we can optimize it out later
            condition       => $<not_test>[1]
                ?? Python2::AST::Node::Test::LogicalCondition.new(condition => 'and')
                !! Nil,
        ));
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
        my $comparison-operator = $/<comparison-operator><not-in>:exists
            ?? 'not-in'
            !! $/<comparison-operator> // '';

        my %operators =
            '==' => '__eq__',
            '!='        => '__ne__',
            '<'         => '__lt__',
            '>'         => '__gt__',
            '<='        => '__le__',
            '>='        => '__ge__',
            'is'        => '__is__',
            'in'        => '__contains__',
            'not-in'    => '__contains__';

        $/.make(Python2::AST::Node::Statement::Test::Comparison.new(
            start-position  	=> $/.from,
            end-position    	=> $/.to,

            # 'not in' is handled as a dedicated operator
            negate              => $comparison-operator eq 'not-in' ?? True !! False,

            left                => $/<expression>[0].made,

            right               => $/<expression>[1]
                ?? $/<expression>[1].made
                !! Nil,

            comparison-operator => $comparison-operator.chars > 0
                ?? %operators{$comparison-operator}
                !! Nil,
        ));
    }

    method function-definition($/) {
        $/.make(Python2::AST::Node::Statement::FunctionDefinition.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name>.made,
            argument-list   => $/<function-definition-argument-list>.made,
            block           => $/<block>.made,
        ));
    }

    method class-definition($/) {
        $/.make(Python2::AST::Node::Statement::ClassDefinition.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name>[0].made,
            block           => $/<block>.made,
            base-class      => $/<name>[1] ?? $/<name>[1].made !! Nil,
        ));
    }

    method statement-return ($/) {
        $/.make(Python2::AST::Node::Statement::Return.new(
            start-position  => $/.from,
            end-position    => $/.to,
            value           => $/.values[0] ?? $/.values[0].made !! Nil,
        ))
    }

    # TODO we should do a a AST intermediate here to provide more data for further optimization
    method function-definition-argument-list($/) {
        my Python2::AST::Node::Statement::FunctionDefinition::Argument @argument-list;

        for $/<function-definition-argument> -> $argument {
            @argument-list.push($argument.made);
        }

        $/.make(@argument-list);
    }

    method function-definition-argument($/) {
        $/.make(Python2::AST::Node::Statement::FunctionDefinition::Argument.new(
            start-position  => $/.from,
            end-position    => $/.to,
            name            => $/<name>.made,
            default-value   => $/<test> ?? $/<test>.made !! Nil,
        ));
    }

    multi method block($/ where $<statement>) {
        my $block = Python2::AST::Node::Block.new(
            start-position  => $/.from,
            end-position    => $/.to,
        );

        for $/<statement> -> $statement {
            $block.statements.push($statement.made);
        }

        $/.make($block);
    }
}
