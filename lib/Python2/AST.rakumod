class Python2::AST {
    class Node {}

    class Node::Root is Node {
        has Node @.nodes;
    }

    # Expressions
    class Node::Expression::Literal::String is Node {
        has Str $.value;
    }

    # Statements
    class Node::Statement::Print is Node {
        has $.expression;
    }
}
