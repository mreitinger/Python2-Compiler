class Python2::AST {
    # base node type, keeps track of where in the source code the node was defined
    class Node {
        # position in the original python file
        has $.start-position = Nil;       # TODO mark as required once we support it everywhere
        has $.end-position   = Nil;       # TODO mark as required once we support it everywhere
    }

    # to level node
    class Node::Root is Node {
        has Node @.nodes is rw;
        has Str  $.input is required;
    }

    class Node::Expression is Node {}

    class Node::Power is Node {
        has Node $.atom     is required is rw;
        has Node @.trailers is required is rw;
    }

    class Node::Atom is Node {
        # if this is false we don't recurse upwards on the stack
        # this is overridden only by VariableAssignment otherwise we would overwrite variables
        # outside of our scope
        has Bool $.recurse      is rw = True;

        has Node $.expression is required is rw;
    }

    class Node::ArgumentList is Node {
        has Node @.arguments is required is rw;
    }


    # expressions
    class Node::Expression::Container is Node {
        # list of bitwise expressions
        has Node @.expressions   is required is rw;

        # list bitwise operators (between the expressions)
        has Str  @.operators     is required is rw;
    }

    class Node::Expression::Literal::String is Node {
        has Str     $.value     is required  is rw;
        has Bool    $.raw       is required;
        has Bool    $.unicode   is required;
    }

    class Node::Expression::Literal::Integer is Node {
        has Int $.value is required  is rw;
    }

    class Node::Expression::Literal::Float is Node {
        has Num $.value is required  is rw;
    }

    class Node::Expression::VariableAccess is Node {
        has Node $.name is required is rw;
    }

    class Node::Expression::ArithmeticOperator is Node {
        has Str $.arithmetic-operator is required  is rw;
    }

    class Node::Expression::ArithmeticExpression is Node {
        has Node @.operations is required is rw;
    }

    class Node::Expression::InstanceVariableAccess is Node {
        has Node $.name is required is rw;
    }

    class Node::Subscript is Node {
        has Node $.value    is required is rw;
        has Node $.target   is rw; # for array slicing
    }

    class Node::Expression::ListDefinition is Node {
        has Node @.expressions is rw;
    }

    class Node::Expression::ExpressionList is Node {
        has Node @.expressions is rw;
    }

    class Node::Expression::TestList is Node {
        has Node @.tests is rw;
        has Bool $.trailing-comma is rw;
    }

    class Node::Expression::DictionaryDefinition is Node {
        has Pair @.entries is required is rw;
    }

    class Node::DictComprehension is Node {
        has Node    @.names         is required is rw;
        has Node    $.iterable      is required is rw;
        has Node    $.key           is required is rw;
        has Node    $.value         is required is rw;
        has Node    $.condition     is rw;
    }

    class Node::Expression::SetDefinition is Node {
        has Node @.entries is required is rw;
    }

    class Node::Expression::FunctionCall is Node {
        has Node    $.atom is required is rw;
        has Node    @.arguments is rw;
    }

    class Node::Expression::MethodCall is Node {
        has Node    $.name is required is rw;
        has Node    @.arguments is required is rw;
    }

    class Node::Name is Node {
        has Str $.name is required is rw;
        # unless this is False we check if it
        # resolves at runtime. this is overridden only by VariableAssignment.
        # even if false everything but the last element (atom and/or trailers) must resolve.
        has Bool $.must-resolve is rw = True;
    }

    class Node::Locals is Node {}


    # Statements
    class Node::Statement::Pass is Node {}

    class Node::Statement::P5Import is Node {
        has Str $.perl5-package-name is required  is rw;
        has Str $.name is required  is rw;
    }

    class Node::Statement::Import is Node {
        has @.modules is required  is rw;
    }

    class Node::Statement::FromImport is Node {
        has Str  $.name is required  is rw;
        has Node $.import-names is required is rw;
    }

    class Node::Statement::ImportNames is Node {
        has Node @.names is required is rw;
    }

    class Node::Test is Node {
        has Node $.condition    is required is rw;
        has Node $.left         is required is rw;
        has Node $.right        is required is rw;
    }

    class Node::Test::Logical is Node {
        has Node $.condition    is required is rw;
        has Node @.values       is rw is required;
    }

    class Node::Test::LogicalCondition is Node {
        has Str $.condition    is required is rw;
    }

    class Node::Statement is Node {
        has Node $.statement is required is rw;
    }

    class Node::Statement::Print is Node {
        has @.values is required is rw;
    }

    class Node::Statement::Continue is Node {}

    class Node::Statement::Del is Node {
        has Node $.name is required is rw;
    }

    class Node::Statement::Assert is Node {
        has Node $.assertion is required is rw;
        has Node $.message is rw;
    }

    class Node::Statement::Raise is Node {
        has Node $.exception is required is rw;
        has Node $.message   is rw;
    }

    class Node::Statement::VariableAssignment is Node {
        has Python2::AST::Node @.targets       is required is rw;
        has                    @.name-filter;
        has Node               $.expression    is required is rw;
    }

    class Node::Statement::ArithmeticAssignment is Node {
        has Node    $.target    is required is rw;
        has Node    $.value     is required is rw;
        has Str     $.operator  is required;
    }

    class Node::Statement::LoopFor is Node {
        has Node    @.names         is required is rw;
        has Node    $.iterable      is required is rw;
        has Node    $.block         is required is rw;
    }

    class Node::Statement::LoopWhile is Node {
        has Node    $.test          is required is rw;
        has Node    $.block         is required is rw;
    }

    class Node::ListComprehension is Node {
        has Node    $.name          is required is rw;
        has Node    $.iterable      is required is rw;
        has Node    $.test          is required is rw;
        has Node    $.condition     is rw;
    }

    class Node::Statement::If is Node {
        has Node    $.test  is required is rw;
        has Node    $.block is required is rw;
        has Node    @.elifs is rw; #optional else-if blocks
        has Node    $.else  is rw;
    }

    class Node::Statement::With is Node {
        has Node    $.test  is required is rw;
        has Node    $.block is required is rw;
        has Node    $.name  is required is rw;
    }

    class Node::Statement::ElIf is Node {
        has Node    $.test  is required is rw;
        has Node    $.block is required is rw;
    }

    class Node::Statement::TryExcept is Node {
        has Node    $.try-block  is required is rw;
        has Node    @.except-blocks is required is rw;
        has Node    $.finally-block is rw;
    }

    class Node::ExceptionClause is Node {
        has Node $.exception is rw; # exception where this block is relevant, optional for plain 'except:'
        has Node $.name  is rw; # name of the variable where we assign the exception to
        has Node $.block is required is rw;
    }

    class Node::Statement::Test::Expression is Node {
        has Node $.expression  is required is rw;
    }

    class Node::Statement::Return is Node {
        has Node $.value is rw;
    }

    class Node::Statement::Break is Node {}

    class Node::Statement::Test::Comparison is Node {
        has Node @.operands is required is rw;
        has Str @.operators is required is rw;
    }

    class Node::Statement::FunctionDefinition is Node {
        has Node    $.name is required is rw;
        has Node    @.argument-list is required is rw;
        has Node    $.block is required is rw;
    }

    class Node::Statement::FunctionDefinition::Argument is Node {
        has Node    $.name is required is rw;
        has Node    $.default-value is rw;
        has Bool    $.splat;
    }

    class Node::Argument is Node {
        has Node    $.value is required;
        has Node    $.name; #optional: could be a named argument
        has Bool    $.splat;
    }

    class Node::LambdaDefinition is Node {
        has Node    @.argument-list is required  is rw;
        has Node    $.block is required is rw;
    }

    class Node::Statement::ClassDefinition is Node {
        has Node    $.name          is required is rw;
        has Node    $.block         is required is rw;
        has Node    $.base-class;
    }

    class Node::Block is Node {
        has Node @.statements is rw;
    }

    class Node::PropertyAccess is Node {
        has Node $.atom           is required is rw;
        has Node::Name $.property is required;
    }

    class Node::SubscriptAccess is Node {
        has Node            $.atom      is required is rw;
        has Node::Subscript $.subscript is required;
    }

    class Node::Call is Node {
        has Node               $.atom    is required;
        has Node::ArgumentList $.arglist is required;
    }

    class Node::Call::Name is Node {
        has Node::Atom         $.name    is required;
        has Node::ArgumentList $.arglist is required;
    }

    class Node::Call::Method is Node {
        has Node               $.atom    is required is rw;
        has Node::Name         $.name    is required;
        has Node::ArgumentList $.arglist is required;
    }

    class Node::Comment is Node {
        has Str $.comment is required is rw;
    }
}
