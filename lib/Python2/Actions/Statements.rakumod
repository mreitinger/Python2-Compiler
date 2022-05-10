use Python2::AST;
use Data::Dump;

class Python2::Actions::Statements {
    method statement ($/) {
        die("Statement Action expects exactly one child but we got { $/.values.elems }")
            unless $/.values.elems == 1;

        $/.make(Python2::AST::Node::Statement.new(
                statement   => $/.values[0].made,
                line-number => $/.prematch.indices("\n").elems+1,
        ));
    }

    method statement-p5import($/) {
        $/.make(Python2::AST::Node::Statement::P5Import.new(
            perl5-package-name  => $/<perl5-package-name>.Str,
            name                => $/<name>.Str
        ));
    }


    method statement-print($/) {
        $/.make(Python2::AST::Node::Statement::Print.new(
            value => $/.values[0].made
        ));
    }

    method variable-assignment($/) {
        $/.make(Python2::AST::Node::Statement::VariableAssignment.new(
            target      => $/<power>.made,
            expression  => $/<test>.made
        ));
    }

    method arithmetic-assignment($/) {
        $/.make(Python2::AST::Node::Statement::ArithmeticAssignment.new(
            target      => $/<power>.made,
            value       => $/<test>.made,
            operator    => $/<arithmetic-assignment-operator>.Str,
        ));
    }

    method statement-loop-for($/) {
        $/.make(Python2::AST::Node::Statement::LoopFor.new(
            name        => $/<name>.made,
            iterable    => $/<expression>.made,
            block       => $/<block>.made,
        ));
    }

    method statement-if($/) {
        $/.make(Python2::AST::Node::Statement::If.new(
            test    => $/<test>.made,
            block   => $/<block>[0].made,
            elifs   => $/<statement-elif>.List.map({ $_.made }),
            else    => $/<block>[1] ?? $/<block>[1].made !! Python2::AST::Node,
        ));
    }

    method statement-elif($/) {
        $/.make(Python2::AST::Node::Statement::ElIf.new(
            test            => $/<test>.made,
            block           => $/<block>.made,
        ));
    }

    method statement-try-except($/) {
        $/.make(Python2::AST::Node::Statement::TryExcept.new(
            try-block       => $/<block>[0].made,
            except-block    => $/<block>[1].made,
            finally-block   => $/<block>[2] ?? $/<block>[2].made !! Python2::AST::Node,
        ));
    }

    multi method test($/ where $/<lambda-definition>) {
        $/.make(Python2::AST::Node::Test.new(
            left        => $<lambda-definition>.made,
            right       => Nil,
            condition   => Nil,
        ));
    }

    multi method test($/) {
        $/.make(Python2::AST::Node::Test.new(
                left      => $<or_test>[0].made,
                right     => $<test>          ?? $<test>.made       !! Nil,
                condition => $<or_test>[1]    ?? $<or_test>[1].made !! Nil,
                ));
    }

    method or_test($/) {
        $/.make(Python2::AST::Node::Test::Logical.new(
            left      => $<and_test>[0].made,
            right     => $<and_test>[1]   ?? $<and_test>[1].made    !! Nil,
            condition => $<and_test>[1]   ?? Python2::AST::Node::Test::LogicalCondition.new(condition => 'or')                   !! Nil,
        ));
    }

    method and_test($/) {
        $/.make(Python2::AST::Node::Test::Logical.new(
            left      => $<not_test>[0].made,
            right     => $<not_test>[1]   ?? $<not_test>[1].made   !! Nil,
            condition => $<not_test>[1]   ?? Python2::AST::Node::Test::LogicalCondition.new(condition => 'and')          !! Nil,
        ));
    }

    multi method not_test($/ where $/<comparison>) {
        $/.make($/<comparison>.made);
    }

    multi method not_test($/ where $/<not_test>) {
        $/.make(Python2::AST::Node::Test::Logical.new(
            left      => $<not_test>.made,
            condition => Python2::AST::Node::Test::LogicalCondition.new(condition => 'not'),
        ));
    }

    method comparison ($/) {
        $/.make(Python2::AST::Node::Statement::Test::Comparison.new(
            left                => $/<expression>[0].made,
            comparison-operator => $/<comparison-operator> ?? $/<comparison-operator>.Str   !! Nil,
            right               => $/<expression>[1]       ?? $/<expression>[1].made        !! Nil,
        ));
    }

    method comparison-operator($/) {
        $/.make(Python2::AST::Node::Statement::Test::ComparisonOperator.new(
            comparison-operator => $/<comparison-operator>.Str
        ));

    }

    method function-definition($/) {
        $/.make(Python2::AST::Node::Statement::FunctionDefinition.new(
            name            => $/<name>.made,
            argument-list   => $/<function-definition-argument-list>.made,
            block           => $/<block>.made,
        ));
    }

    method class-definition($/) {
        $/.make(Python2::AST::Node::Statement::ClassDefinition.new(
            name    => $/<name>.made,
            block   => $/<block>.made,
        ));
    }

    method statement-return ($/) {
        $/.make(Python2::AST::Node::Statement::Return.new(
            value => $/.values[0] ?? $/.values[0].made !! Nil,
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
            name            => $/<name>.made,
            default-value   => $/<test> ?? $/<test>.made !! Nil,
        ));
    }

    multi method block($/ where $<statement>) {
        my $block = Python2::AST::Node::Block.new();

        for $/<statement> -> $statement {
            $block.statements.push($statement.made);
        }

        $/.make($block);
    }
}
