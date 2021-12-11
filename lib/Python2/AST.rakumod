class Python2::AST {
    class Node {}

    class Node::Root is Node {
        has Node @.nodes;
    }

    # Expressions
    class Node::Expression::Literal::String is Node {
        has Str $.value;
    }

    class Node::Expression::Literal::Integer is Node {
        has Int $.value;
    }

    class Node::Expression::VariableAccess is Node {
        has Str     $.variable-name;
    }

    class Node::Expression::ListDefinition is Node {
        has Node @.expressions;
    }

    class Node::Expression::ExpressionList is Node {
        has Node @.expressions;
    }

    class Node::Expression::DictionaryDefinition is Node {
        has Node %.entries;
    }

    # Arithmetic
    class Node::Expression::ArithmeticOperation is Node {
        has Int $.left;
        has Int $.right;
        has Str $.operator; # TODO validationf
    }

    # Statements
    class Node::Statement::Print is Node {
        has $.expression;
    }

    class Node::Statement::VariableAssignment is Node {
        has Str     $.variable-name;
        has Node    $.expression;
    }

    class Node::Statement::LoopFor is Node {
        has Str     $.variable-name;
        has Node    $.iterable;
        has Node    $.suite;
    }

    class Node::Suite is Node {
        has Node @.statements;
    }

}
