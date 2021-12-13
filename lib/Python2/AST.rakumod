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

    # Arithmetic
    class Node::Expression::ArithmeticOperation is Node {
        has $.left          is required;
        has $.right         is required;
        has Str $.operator  is required; # TODO validation
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

    class Node::Suite is Node {
        has Node @.statements;
    }

}
