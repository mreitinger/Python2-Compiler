use Python2::AST;
use Data::Dump;

class Python2::Actions::Statements {
    multi method statement($/ where $<expression>) {
        $/.make(Python2::AST::Node::Statement.new(
            statement => $/<expression>.made
        ));
    }

    multi method statement($/ where $<statement-print>) {
        $/.make(Python2::AST::Node::Statement.new(
            statement => $/<statement-print>.made
        ));
    }

    multi method statement($/ where $<variable-assignment>) {
        $/.make(Python2::AST::Node::Statement.new(
            statement => $/<variable-assignment>.made
        ));
    }

    multi method statement($/ where $<statement-loop-for>) {
        $/.make(Python2::AST::Node::Statement.new(
            statement => $/<statement-loop-for>.made
        ));
    }

    multi method statement($/ where $<statement-if>) {
        $/.make(Python2::AST::Node::Statement.new(
            statement => $/<statement-if>.made
        ));
    }

    multi method statement($/ where $<function-definition>) {
        $/.make(Python2::AST::Node::Statement.new(
            statement => $/<function-definition>.made
        ));
    }

    multi method statement($/ where $<class-definition>) {
        $/.make(Python2::AST::Node::Statement.new(
            statement => $/<class-definition>.made
        ));
    }

    multi method statement($/ where $<statement-try-except>) {
        $/.make(Python2::AST::Node::Statement.new(
            statement => $/<statement-try-except>.made
        ));
    }

    multi method statement-print($/ where $/<expression>) {
        $/.make(Python2::AST::Node::Statement::Print.new(
            value => $/<expression>.made
        ));
    }

    multi method statement-print($/ where $/<function-call>) {
        $/.make(Python2::AST::Node::Statement::Print.new(
            value => $/<function-call>.made
        ));
    }

    multi method variable-assignment($/) {
        $/.make(Python2::AST::Node::Statement::VariableAssignment.new(
            variable-name   => $/<variable-name>.Str,
            expression      => $/<expression>.made
        ));
    }

    multi method statement-loop-for($/) {
        $/.make(Python2::AST::Node::Statement::LoopFor.new(
            variable-name   => $/<variable-name>.Str,
            iterable        => $/<expression>.made,
            block           => $/<block>.made,
        ));
    }

    multi method statement-if($/) {
        $/.make(Python2::AST::Node::Statement::If.new(
            test            => $/<test>.made,
            block           => $/<block>[0].made,
            else            => $/<block>[1] ?? $/<block>[1].made !! Python2::AST::Node,
        ));
    }

    multi method statement-try-except($/) {
        $/.make(Python2::AST::Node::Statement::TryExcept.new(
            try-block       => $/<block>[0].made,
            except-block    => $/<block>[1].made,
            finally-block   => $/<block>[2] ?? $/<block>[2].made !! Python2::AST::Node,
        ));
    }

    multi method test($/ where $/<comparison-operator>) {
        $/.make(Python2::AST::Node::Statement::Test::Comparison.new(
            left                => $/<expression>[0].made,
            comparison-operator => $/<comparison-operator>.Str,
            right               => $/<expression>[1].made,
        ));
    }

    multi method test($/) {
        $/.make(Python2::AST::Node::Statement::Test::Expression.new(
            expression => $/<expression>[0].made, # the 'test' rule has alternatives with >1 expression
                                                  # so we seem to get an array all the time
        ));
    }

    multi method comparison-operator($/) {
        $/.make(Python2::AST::Node::Statement::Test::ComparisonOperator.new(
            comparison-operator => $/<comparison-operator>.Str
        ));

    }
    multi method function-definition($/) {
        $/.make(Python2::AST::Node::Statement::FunctionDefinition.new(
            function-name   => $/<function-name>.Str,
            argument-list   => $/<function-definition-argument-list>.made,
            block           => $/<block>.made,
        ));
    }

    multi method class-definition($/) {
        $/.make(Python2::AST::Node::Statement::ClassDefinition.new(
            class-name  => $/<class-name>.Str,
            block       => $/<block>.made,
        ));
    }

    # TODO we should do a a AST intermediate here to provide more data for further optimization
    method function-definition-argument-list($/) {
        my Str @argument-list;

        for $/<variable-name> -> $argument {
            @argument-list.push($argument.Str);
        }

        $/.make(@argument-list);
    }

    multi method block($/ where $<statement>) {
        my $block = Python2::AST::Node::Block.new();

        for $/<statement> -> $statement {
            $block.statements.push($statement.made);
        }

        $/.make($block);
    }

    multi method statement ($/) {
        die("Action for statement not implemented: " ~ dd($/))
    }
}
