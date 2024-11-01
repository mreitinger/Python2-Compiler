use Python2::AST;

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

    method calculate-types(Python2::AST::Type $context?) {
        $.context = $context;
        if $.word {
            given $.word {
                $.type = Python2::AST::Request when 'REQUEST';
            }
        }
        else {
            $.expression.calculate-types($context);
            $.type = $.expression.type;
        }
    }
}

class DTML::AST::Attribute is Node {
    has Str $.name;
    has Str $.value;
    has DTML::AST::Expression $.expression;

    method value-escaped() {
        $.value.subst(Q'\', Q'\\', :g).subst(Q"'", Q"\'", :g)
    }
}

role DTML::AST::WithAttributes {
    has Node @.attributes;

    method has-attr($name) {
        @!attributes and @!attributes.any.name eq $name
    }

    method attr($name) {
        @!attributes.first(*.name eq $name);
    }
}

class DTML::AST::Template is Node {
    has Str $.input;
    has Node @.chunks;

    method calculate-types(Python2::AST::Type $context?) {
        $.context = Python2::AST::ZMSObject;
        .calculate-types(Python2::AST::ZMSObject) for @.chunks;
    }
}

class DTML::AST::Content is Node {
    has Str $.content;
}

class DTML::AST::Declaration is Node {
    has Str $.name;
    has DTML::AST::Expression $.expression;

    method calculate-types(Python2::AST::Type $context?) {
        $.context = $context;
        $.expression.calculate-types($context);
        $.type = $.expression.type;
    }
}

class DTML::AST::Var is Node does DTML::AST::WithAttributes {
    has DTML::AST::Attribute $.dump;
    has DTML::AST::Attribute $.fmt;
    has DTML::AST::Attribute $.size;
    has DTML::AST::Attribute $.etc;
    has DTML::AST::Attribute $.remove_attributes;
    has DTML::AST::Attribute $.remove_tags;
    has DTML::AST::Attribute $.tag_content_only;
    has DTML::AST::Expression $.expression;
}

class DTML::AST::Return is Node does DTML::AST::WithAttributes {
    has DTML::AST::Expression $.expression;
}

class DTML::AST::If is Node {
    has $.if = 'if';
    has DTML::AST::Expression $.expression;
    has Node @.then;
    has Node @.elif;
    has Node @.else;
}

class DTML::AST::Elif is Node {
    has DTML::AST::Expression $.expression;
    has Node @.chunks;
}

class DTML::AST::Let is Node {
    has Node @.declarations;
    has Node @.chunks;

    method calculate-types(Python2::AST::Type $context?) {
        $.context = $context;
        .calculate-types($context) for @.declarations;
        .calculate-types($context) for @.chunks;
    }
}

class DTML::AST::With is Node {
    has DTML::AST::Expression $.expression;
    has Node @.chunks;

    method calculate-types(Python2::AST::Type $context?) {
        $.context = $context;
        $.expression.calculate-types($context);
        my $inner-context = $.expression.type;
        .calculate-types($inner-context) for @.chunks;
    }
}

class DTML::AST::In is Node does DTML::AST::WithAttributes {
    has DTML::AST::Attribute $.reverse;
    has DTML::AST::Attribute $.start;
    has DTML::AST::Attribute $.end;
    has DTML::AST::Attribute $.size;
    has DTML::AST::Expression $.expression;
    has Node @.chunks;

    method calculate-type(Python2::AST::Type $context?) {
        $.context = Python2::AST::Type;
    }
}

class DTML::AST::Call is Node {
    has DTML::AST::Expression $.expression;
}

class DTML::AST::Try is Node {
    has Node @.chunks;
    has Node @.except;
}

class DTML::AST::Raise is Node {
    has DTML::AST::Content $.content;
}

class DTML::AST::Zms is Node does DTML::AST::WithAttributes {
    has DTML::AST::Attribute $.id;
    has DTML::AST::Attribute $.caption;
    has DTML::AST::Attribute $.class;
    has DTML::AST::Attribute $.max_children;

    has DTML::AST::Attribute $.obj;
    has DTML::AST::Attribute $.level;
    has DTML::AST::Attribute $.activenode;
    has DTML::AST::Attribute $.treenode_filter;
    has DTML::AST::Attribute $.content_switch;

    method default-value-attribute($attr, $default) {
        "$attr => '{ $.attr($attr).value or $default }'"
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
