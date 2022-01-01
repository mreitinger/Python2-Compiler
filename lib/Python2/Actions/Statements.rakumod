use Python2::AST;
use Data::Dump;

class Python2::Actions::Statements {
    method statement ($/) {
        die("Statement Action expects exactly one child but we got { $/.values.elems }")
            unless $/.values.elems == 1;

        $/.make(Python2::AST::Node::Statement.new(
                statement => $/.values[0].made
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

    method variable-assignment($/) {
        $/.make(Python2::AST::Node::Statement::VariableAssignment.new(
            variable-name   => $/<variable-name>.Str,
            expression      => $/<expression>.made
        ));
    }

    method instance-variable-assignment($/) {
        # the final node in the chain ('object.foo.bar().final_node'). this doesn't get passed
        # to getvar since we need it as a parameter for setvar instead. getvar will only traverse
        # up to the parent object
        # TODO this could be handled a bit cleaner by capturing a trailing variable-name
        my $final-node = pop $/<object-access-operation>;

        my Python2::AST::Node @operations;

        for ($/<object-access-operation>) -> $operation {
            push(@operations, $operation.made);
        }

        $/.make(Python2::AST::Node::Statement::InstanceVariableAssignment.new(
            object-access   => Python2::AST::Node::Expression::ObjectAccess.new(
                object-name => $/<variable-name>.Str,
                operations  => @operations,
            ),
            target-variable => $final-node.made,
            expression      => $/<expression>.made
        ));
    }

    method statement-loop-for($/) {
        $/.make(Python2::AST::Node::Statement::LoopFor.new(
            variable-name   => $/<variable-name>.Str,
            iterable        => $/<expression>.made,
            block           => $/<block>.made,
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

    method comparison-operator($/) {
        $/.make(Python2::AST::Node::Statement::Test::ComparisonOperator.new(
            comparison-operator => $/<comparison-operator>.Str
        ));

    }

    method function-definition($/) {
        $/.make(Python2::AST::Node::Statement::FunctionDefinition.new(
            function-name   => $/<function-name>.Str,
            argument-list   => $/<function-definition-argument-list>.made,
            block           => $/<block>.made,
        ));
    }

    method class-definition($/) {
        $/.make(Python2::AST::Node::Statement::ClassDefinition.new(
            class-name  => $/<class-name>.Str,
            block       => $/<block>.made,
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
}
