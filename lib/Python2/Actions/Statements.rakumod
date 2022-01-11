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

    method instance-variable-assignment($/) {
        # the final node in the chain ('object.foo.bar().final_node'). this doesn't get passed
        # to getvar since we need it as a parameter for setvar instead. getvar will only traverse
        # up to the parent object
        # TODO this could be handled a bit cleaner by capturing a trailing name
        my $final-node = pop $/<object-access-operation>;

        my Python2::AST::Node @operations;

        for ($/<object-access-operation>) -> $operation {
            push(@operations, $operation.made);
        }

        $/.make(Python2::AST::Node::Statement::InstanceVariableAssignment.new(
                object-access   => Python2::AST::Node::Expression::ObjectAccess.new(
                name            => $/<name>.made,
                operations      => @operations,
            ),
            target-variable         => $final-node.made,
            list-or-dict-element    => $/<list-or-dict-element>.made,
            expression              => $/<expression>.made
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
            test            => $/<test>.made,
            block           => $/<block>[0].made,
            else            => $/<block>[1] ?? $/<block>[1].made !! Python2::AST::Node,
        ));
    }

    method statement-try-except($/) {
        $/.make(Python2::AST::Node::Statement::TryExcept.new(
            try-block       => $/<block>[0].made,
            except-block    => $/<block>[1].made,
            finally-block   => $/<block>[2] ?? $/<block>[2].made !! Python2::AST::Node,
        ));
    }

    method test($/ where $/<comparison>) {
        $/.make(Python2::AST::Node::Test.new(
            left      => $<comparison>[0].made,
            right     => $<test>          ?? $<test>.made          !! Nil,
            condition => $<comparison>[1] ?? $<comparison>[1].made !! Nil,
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
            value => $/.values[0].made,
        ))
    }

    # TODO we should do a a AST intermediate here to provide more data for further optimization
    method function-definition-argument-list($/) {
        my Str @argument-list;

        for $/<name> -> $argument {
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
}
