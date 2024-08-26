use Python2::AST;

class DTML::AST::Template {
    has Str $.input;
    has @.chunks;
}

class DTML::AST::Content {
    has Str $.content;
}

class DTML::AST::Var {
    has Str $.word;
    has Python2::AST::Node::Expression::TestList $.expression;
}

class DTML::AST::If {
    has Str $.word;
    has Python2::AST::Node::Expression::TestList $.expression;
    has @.chunks;
}
