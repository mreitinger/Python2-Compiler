use Python2::AST;

role DTML::AST::WithAttributes {
    has @.attributes;

    method has-attr($name) {
        @!attributes and @!attributes.any.name eq $name
    }

    method attr($name) {
        @!attributes.first(*.name eq $name).value;
    }
}

class DTML::AST::Template {
    has Str $.input;
    has @.chunks;
}

class DTML::AST::Content {
    has Str $.content;
}

class DTML::AST::Expression {
    has Str $.word;
    has Python2::AST::Node::Expression::TestList $.expression;

    method escaped-gist() {
        my $code = $!word // $!expression.gist; # TODO use source
        $code.subst('"', '\"', :g)
    }
}

class DTML::AST::Declaration {
    has Str $.name;
    has DTML::AST::Expression $.expression;
}

class DTML::AST::Var does DTML::AST::WithAttributes {
    has DTML::AST::Expression $.expression;
}

class DTML::AST::Return does DTML::AST::WithAttributes {
    has DTML::AST::Expression $.expression;
}

class DTML::AST::If {
    has $.if = 'if';
    has DTML::AST::Expression $.expression;
    has @.then;
    has @.elif;
    has @.else;
}

class DTML::AST::Elif {
    has DTML::AST::Expression $.expression;
    has @.chunks;
}

class DTML::AST::Let {
    has @.declarations;
    has @.chunks;
}

class DTML::AST::With {
    has DTML::AST::Expression $.expression;
    has @.chunks;
}

class DTML::AST::In does DTML::AST::WithAttributes {
    has DTML::AST::Expression $.expression;
    has @.chunks;
}

class DTML::AST::Call {
    has DTML::AST::Expression $.expression;
}

class DTML::AST::Try {
    has @.chunks;
    has @.except;
}

class DTML::AST::Zms does DTML::AST::WithAttributes {
    has Python2::AST::Node::Expression::TestList $.obj;
    has Python2::AST::Node::Expression::TestList $.level;
    has Python2::AST::Node::Expression::TestList $.activenode;
    has Python2::AST::Node::Expression::TestList $.treenode_filter;
    has Python2::AST::Node::Expression::TestList $.content_switch;

    method value-attribute($attr) {
        return Slip unless self.has-attr($attr);
        "$attr => '$.attr($attr)'"
    }
    method default-value-attribute($attr, $default) {
        "$attr => '{ $.attr($attr) or $default }'"
    }

    method use-caption-images() {
        'use_caption_images => ' ~ (
            (self.has-attr('no_caption_images') and self.attr('no_caption_images'))
            ?? 0
            !! 1
        );
    }
}

class DTML::AST::Attribute {
    has Str $.name;
    has Str $.value;
}

class DTML::AST::Include {
    has Str $.file;
}

class DTML::AST::Comment {
}
