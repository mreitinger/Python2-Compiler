class Python2::AST {
    class Node {}

    class Node::Root is Node {
        has Node @.nodes is rw;
    }

    class Node::Expression is Node {}

    class Node::Name is Node {
        has Str $.name is required is rw;
    }

    class Node::Statement::P5Import is Node {
        has Str $.perl5-package-name is required  is rw;
        has Str $.name is required  is rw;
    }

    class Node::Power is Node {
        has Node $.atom     is required is rw;
        has Node @.trailers is required is rw;
    }

    class Node::Atom is Node {
        has Node $.expression is required is rw;
    }

    class Node::Test is Node {
        has Node $.condition    is required is rw;
        has Node $.left         is required is rw;
        has Node $.right        is required is rw;
    }

    class Node::Test::Logical is Node {
        has Node $.condition    is required is rw;
        has Node $.left         is rw is required;
        has Node $.right        is rw; # not provides not 'right'
    }

    class Node::Test::LogicalCondition is Node {
        has Str $.condition    is required is rw;
    }

    # Expressions
    class Node::Expression::Container is Node::Expression {
        has Node $.expression   is required is rw;
    }

    class Node::Expression::Literal is Node::Expression {}

    class Node::Expression::Literal::String is Node::Expression::Literal {
        has Str     $.value is required  is rw;
        has Bool    $.raw   is required;
    }

    class Node::Expression::Literal::Integer is Node::Expression::Literal {
        has Int $.value is required  is rw;
    }

    class Node::Expression::Literal::Float is Node::Expression::Literal {
        has Num $.value is required  is rw;
    }

    class Node::Expression::VariableAccess is Node::Expression {
        has Node $.name is required is rw;
    }

    class Node::Expression::ArithmeticOperator is Node::Expression {
        has Str $.arithmetic-operator is required  is rw;
    }

    class Node::Expression::ArithmeticExpression is Node::Expression {
        has Node @.operations is required is rw;
    }

    class Node::Expression::InstanceVariableAccess is Node::Expression {
        has Node $.name is required is rw;
    }

    class Node::Subscript is Node::Expression {
        has Node $.value    is required is rw;
        has Node $.target   is rw; # for array slicing
    }

    class Node::Expression::ListDefinition is Node::Expression {
        has Node @.expressions is rw;
    }

    class Node::Expression::ExpressionList is Node::Expression {
        has Node @.expressions is rw;
    }

    class Node::Expression::TestList is Node {
        has Node @.tests is rw;
    }

    class Node::Expression::DictionaryDefinition is Node::Expression {
        has Pair @.entries is required is rw;
    }

    class Node::Expression::FunctionCall is Node::Expression {
        has Node    $.atom is required is rw;
        has Node    @.arguments is rw;
    }

    class Node::Expression::MethodCall is Node::Expression {
        has Node    $.name is required is rw;
        has Node    @.arguments is required is rw;
    }

    class Node::ArgumentList is Node {
        has Node @.arguments is required is rw;
    }

    # Statements
    class Node::Statement is Node::Expression {
        has Node $.statement is required is rw;
    }

    class Node::Statement::Print is Node::Expression {
        has $.value is required is rw;
    }

    class Node::Statement::VariableAssignment is Node::Expression {
        has Node    $.target        is required is rw;
        has Node    $.expression    is required is rw;
    }

    class Node::Statement::ArithmeticAssignment is Node::Expression {
        has Node    $.target    is required is rw;
        has Node    $.value     is required is rw;
        has Str     $.operator  is required;
    }

    class Node::Statement::LoopFor is Node::Expression {
        has Node    $.name          is required is rw;
        has Node    $.iterable      is required is rw;
        has Node    $.block         is required is rw;
    }

    class Node::Statement::If is Node::Expression {
        has Node    $.test  is required is rw;
        has Node    $.block is required is rw;
        has Node    @.elifs is rw; #optional else-if blocks
        has Node    $.else  is rw;
    }

    class Node::Statement::ElIf is Node::Expression {
        has Node    $.test  is required is rw;
        has Node    $.block is required is rw;
    }

    class Node::Statement::TryExcept is Node::Expression {
        has Node    $.try-block  is required is rw;
        has Node    $.except-block is required is rw;
        has Node    $.finally-block is rw;
    }


    class Node::Statement::Test::Expression is Node::Expression {
        has Node $.expression  is required is rw;
    }

    class Node::Statement::Return is Node {
        has Node $.value is rw;
    }

    class Node::Statement::Test::Comparison is Node::Expression {
        has Node $.left     is required is rw;
        has Node $.right    is rw;
        has Str $.comparison-operator;
    }

    class Node::Statement::FunctionDefinition is Node::Expression {
        has Node    $.name is required is rw;
        has Node    @.argument-list is required is rw;
        has Node    $.block is required is rw;
    }

    class Node::Statement::FunctionDefinition::Argument is Node {
        has Node    $.name is required is rw;
        has Node    $.default-value is rw;
    }

    class Node::Argument is Node {
        has Node    $.value is required;
        has Node    $.name; #optional: could be a named argument
    }

    class Node::LambdaDefinition is Node::Expression {
        has Node    @.argument-list is required  is rw;
        has Node    $.block is required is rw;
    }

    class Node::Statement::ClassDefinition is Node::Expression {
        has Node    $.name is required is rw;
        has Node    $.block is required is rw;
    }

    class Node::Block is Node {
        has Node @.statements is rw;
    }

    class Node::Comment is Node {
        has Str $.comment is required is rw;
    }
}
