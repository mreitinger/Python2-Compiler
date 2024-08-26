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

class DTML::AST::Template is Node {
    has Str $.input;
    has @.chunks;
}

class DTML::AST::Content is Node {
    has Str $.content;
}

class DTML::AST::Expression is Node {
    has Str $.word;
    has Python2::AST::Node::Expression::TestList $.expression;

    method escaped-gist() {
        my $code;
        if $*DTML-SOURCE {
            $code = $*DTML-SOURCE.substr($.start-position + 1, $.end-position - $.start-position - 2);
        }
        else {
            $code = $!word // $!expression.gist;
        }
        $code.subst('"', '\"', :g)
    }
}

class DTML::AST::Declaration is Node {
    has Str $.name;
    has DTML::AST::Expression $.expression;
}

class DTML::AST::Var is Node does DTML::AST::WithAttributes {
    has DTML::AST::Expression $.expression;
}

class DTML::AST::Return is Node does DTML::AST::WithAttributes {
    has DTML::AST::Expression $.expression;
}

class DTML::AST::If is Node {
    has $.if = 'if';
    has DTML::AST::Expression $.expression;
    has @.then;
    has @.elif;
    has @.else;
}

class DTML::AST::Elif is Node {
    has DTML::AST::Expression $.expression;
    has @.chunks;
}

class DTML::AST::Let is Node {
    has @.declarations;
    has @.chunks;
}

class DTML::AST::With is Node {
    has DTML::AST::Expression $.expression;
    has @.chunks;
}

class DTML::AST::In is Node does DTML::AST::WithAttributes {
    has DTML::AST::Expression $.expression;
    has @.chunks;
}

class DTML::AST::Call is Node {
    has DTML::AST::Expression $.expression;
}

class DTML::AST::Try is Node {
    has @.chunks;
    has @.except;
}

class DTML::AST::Zms is Node does DTML::AST::WithAttributes {
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

class DTML::AST::Include is Node {
    has Str $.file;
}

class DTML::AST::Comment is Node {
}

class DTML::AST::Attribute is Node {
    has Str $.name;
    has Str $.value;
}
