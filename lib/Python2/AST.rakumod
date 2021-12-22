class Python2::AST {
    class Node {}

    class Node::Root is Node {
        has Node @.nodes;
    }

    # Expressions
    class Node::Expression::Literal::String is Node {
        has Str $.value is required;
    }

    class Node::Expression::Literal::Integer is Node {
        has Int $.value is required;
    }

    class Node::Expression::Literal::Float is Node {
        has Num $.value is required;
    }

    class Node::Expression::VariableAccess is Node {
        has Str $.variable-name is required;
    }

    class Node::Expression::ArithmeticOperator is Node {
        has Str $.arithmetic-operator is required;
    }

    class Node::Expression::InstanceVariableAccess is Node {
        has Str $.object-name is required;
        has Str $.variable-name is required;
    }

    class Node::Expression::ListDefinition is Node {
        has Node @.expressions;
    }

    class Node::Expression::ExpressionList is Node {
        has Node @.expressions;
    }

    class Node::Expression::DictionaryDefinition is Node {
        has Node %.entries is required;
    }

    class Node::Expression::FunctionCall is Node {
        has Str     $.function-name is required;
        has Node    @.arguments;
    }

    class Node::Expression::MethodCall is Node {
        has Node    $.object is required;
        has Str     $.method-name is required;
        has Node    @.arguments;
    }

    # Arithmetic
    class Node::Expression::ArithmeticOperation is Node {
        has Node @.operations is required;
    }

    # Statements
    class Node::Statement is Node {
        has Node $.statement is required;
    }

    class Node::Statement::Print is Node {
        has $.value is required;
    }

    class Node::Statement::VariableAssignment is Node {
        has Str     $.variable-name is required;
        has Node    $.expression    is required;
    }

    class Node::Statement::LoopFor is Node {
        has Str     $.variable-name is required;
        has Node    $.iterable      is required;
        has Node    $.suite         is required;
    }

    class Node::Statement::If is Node {
        has Node    $.test  is required;
        has Node    $.suite is required;
    }

    class Node::Statement::TryExcept is Node {
        has Node    $.try-suite  is required;
        has Node    $.except-suite is required;
    }


    class Node::Statement::Test::Expression is Node {
        has Node $.expression  is required;
    }

    class Node::Statement::Test::Comparison is Node {
        has Node $.left is required;
        has Str $.comparison-operator is required;
        has Node $.right is required;
    }

    class Node::Statement::FunctionDefinition is Node {
        has Str     $.function-name is required;
        has Str     @.argument-list is required;
        has Node    $.suite is required;
    }

    class Node::Statement::ClassDefinition is Node {
        has Str     $.class-name is required;
        has Node    $.suite is required;
    }

    class Node::Suite is Node {
        has Node @.statements;
    }

}
