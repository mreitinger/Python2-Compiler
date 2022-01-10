class Python2::AST {
    class Node {}

    class Node::Root is Node {
        has Node @.nodes;
    }

    class Node::Expression is Node {}

    class Node::Name is Node {
        has Str $.name is required;
    }

    # Expressions
    class Node::Expression::Container is Node::Expression {
        has Node::Expression $.expression is required;
    }

    class Node::Expression::Literal::String is Node::Expression {
        has Str $.value is required;
    }

    class Node::Expression::Literal::Integer is Node::Expression {
        has Int $.value is required;
    }

    class Node::Expression::Literal::Float is Node::Expression {
        has Num $.value is required;
    }

    class Node::Expression::VariableAccess is Node::Expression {
        has Node $.name is required;
    }

    class Node::Expression::ArithmeticOperator is Node::Expression {
        has Str $.arithmetic-operator is required;
    }

    class Node::Expression::InstanceVariableAccess is Node::Expression {
        has Node $.name is required;
    }

    class Node::Expression::DictionaryAccess is Node::Expression {
        has Node $.dictionary-name  is required;
        has Str $.key               is required;
    }

    class Node::Expression::ListDefinition is Node::Expression {
        has Node @.expressions;
    }

    class Node::Expression::ExpressionList is Node::Expression {
        has Node @.expressions;
    }

    class Node::Expression::DictionaryDefinition is Node::Expression {
        has Node %.entries is required;
    }

    class Node::Expression::FunctionCall is Node::Expression {
        has Node    $.name is required;
        has Node    @.arguments;
    }

    class Node::Expression::ObjectAccess is Node::Expression {
        has Node    $.name   is required;
        has Node    @.operations    is required;
    }

    class Node::Expression::MethodCall is Node::Expression {
        has Node    $.name is required;
        has Node    @.arguments is required;
    }

    # Arithmetic
    class Node::Expression::ArithmeticOperation is Node::Expression {
        has Node @.operations is required;
    }

    # Statements
    class Node::Statement is Node::Expression {
        has Node $.statement is required;
    }

    class Node::Statement::Print is Node::Expression {
        has $.value is required;
    }

    class Node::Statement::VariableAssignment is Node::Expression {
        has Node    $.name is required;
        has Node    $.expression    is required;
        has Node    $.list-or-dict-element;
    }

    class Node::Statement::InstanceVariableAssignment is Node::Expression {
        has Node::Expression::ObjectAccess  $.object-access         is required;
        has Node                            $.target-variable       is required;
        has Node                            $.list-or-dict-element;
        has Node::Expression                $.expression            is required;
    }

    class Node::Statement::LoopFor is Node::Expression {
        has Node    $.name          is required;
        has Node    $.iterable      is required;
        has Node    $.block         is required;
    }

    class Node::Statement::If is Node::Expression {
        has Node    $.test  is required;
        has Node    $.block is required;
        has Node    $.else;
    }

    class Node::Statement::TryExcept is Node::Expression {
        has Node    $.try-block  is required;
        has Node    $.except-block is required;
        has Node    $.finally-block;
    }


    class Node::Statement::Test::Expression is Node::Expression {
        has Node $.expression  is required;
    }

    class Node::Statement::Return is Node {
        has Node $.value  is required;
    }

    class Node::Statement::Test::Comparison is Node::Expression {
        has Node $.left is required;
        has Str $.comparison-operator is required;
        has Node $.right is required;
    }

    class Node::Statement::FunctionDefinition is Node::Expression {
        has Node    $.name is required;
        has Str     @.argument-list is required;
        has Node    $.block is required;
    }

    class Node::Statement::ClassDefinition is Node::Expression {
        has Node    $.name is required;
        has Node    $.block is required;
    }

    class Node::Block is Node {
        has Node @.statements;
    }

    class Node::Comment is Node {
        has Str $.comment is required;
    }
}
