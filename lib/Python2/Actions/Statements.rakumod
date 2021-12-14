use Python2::AST;
use Data::Dump;

class Python2::Actions::Statements {
    multi method statement($/ where $<expression>) {
        $/.make($<expression>.made);
    }

    multi method statement($/ where $<statement-print>) {
        $/.make($<statement-print>.made);
    }

    multi method statement($/ where $<variable-assignment>) {
        $/.make($<variable-assignment>.made);
    }

    multi method statement($/ where $<statement-loop-for>) {
        $/.make($<statement-loop-for>.made);
    }

    multi method statement($/ where $<statement-if>) {
        $/.make($<statement-if>.made);
    }

    multi method statement($/ where $<function-definition>) {
        $/.make($<function-definition>.made);
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
            suite           => $/<suite>.made,
        ));
    }

    multi method statement-if($/) {
        $/.make(Python2::AST::Node::Statement::If.new(
            test            => $/<expression>.made,
            suite           => $/<suite>.made,
        ));
    }

    multi method function-definition($/) {
        $/.make(Python2::AST::Node::Statement::FunctionDefinition.new(
            function-name   => $/<function-name>.Str,
            argument-list   => $/<function-definition-argument-list>.made,
            suite           => $/<suite>.made,
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

    multi method suite($/ where $<statement>) {
        my $suite = Python2::AST::Node::Suite.new();

        for $/<statement> -> $statement {
            $suite.statements.push($statement.made);
        }

        $/.make($suite);
    }

    multi method statement ($/) {
        die("Action for statement not implemented: " ~ $/)
    }
}