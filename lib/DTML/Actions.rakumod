use DTML::AST;
use Python2::AST;
use Python2::Actions::Expressions;

unit class DTML::Actions
    does Python2::Actions::Expressions;

method TOP($/) {
    make DTML::AST::Template.new(
        :input($/.Str)
        :chunks($<chunk>».ast),
        :start-position($/.from),
        :end-position($/.to),
    );
}

method chunk($/) {
    make $<dtml>
        ?? $<dtml>.ast
        !! $<include>
            ?? $<include>.ast
            !! $<content>.ast;
}

method content($/) {
    make DTML::AST::Content.new(
        :content($/.Str),
        :start-position($/.from),
        :end-position($/.to),
    );
}

method include($/) {
    make DTML::AST::Include.new(
        :file($<file>.Str),
        :start-position($/.from),
        :end-position($/.to),
    );
}

method dtml:sym<var>($/) {
    make $<word>
        ?? DTML::AST::Var.new(
            :expression(DTML::AST::Expression.new(:word($<word>.ast))),
            :attributes($<dtml-entity-attribute>».ast),
            :start-position($/.from),
            :end-position($/.to),
        )
        !! DTML::AST::Var.new(
            :expression($<dtml-expression>.ast),
            :attributes($<dtml-attribute>».ast),
            :start-position($/.from),
            :end-position($/.to),
        )
}

method dtml:sym<return>($/) {
    make DTML::AST::Return.new(
        :expression($<dtml-expression>.ast),
        :attributes($<dtml-attribute>».ast),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml:sym<if>($/) {
    make DTML::AST::If.new(
        :expression($<dtml-expression>.ast),
        :then($<then>».ast),
        :elif($<dtml-elif>».ast),
        :else($<else>».ast),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml-elif($/) {
    make DTML::AST::Elif.new(
        :expression($<dtml-expression>.ast),
        :chunks($<chunk>».ast),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml:sym<unless>($/) {
    make $<else>
        ?? DTML::AST::If.new(
            :if('unless'),
            :expression($<dtml-expression>.ast),
            :then($<then>».ast),
            :else($<else>».ast),
            :start-position($/.from),
            :end-position($/.to),
        )
        !! DTML::AST::If.new(
            :if('unless'),
            :expression($<dtml-expression>.ast),
            :then($<then>».ast),
            :start-position($/.from),
            :end-position($/.to),
        )
}

method dtml:sym<let>($/) {
    make DTML::AST::Let.new(
        :declarations($<dtml-declaration>».ast),
        :chunks($<chunk>».ast),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml:sym<with>($/) {
    make DTML::AST::With.new(
        :expression($<dtml-expression>.ast),
        :chunks($<chunk>».ast),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml:sym<in>($/) {
    make DTML::AST::In.new(
        :expression($<dtml-expression>.ast),
        :attributes($<dtml-attribute>».ast),
        :chunks($<chunk>».ast),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml:sym<call>($/) {
    make DTML::AST::Call.new(
        :expression($<dtml-expression>.ast),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml:sym<try>($/) {
    make DTML::AST::Try.new(
        :chunks($<chunk>».ast),
        :except($<dtml-except> ?? $<dtml-except><chunk>».ast !! []),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml:sym<zms>($/) {
    make DTML::AST::Zms.new(
        :obj($<obj> ?? $<obj>[0]<test-list>.ast !! Nil),
        :level($<level> ?? $<level>[0]<test-list>.ast !! Nil),
        :activenode($<activenode> ?? $<activenode>[0]<test-list>.ast !! Nil),
        :treenode_filter($<treenode_filter> ?? $<treenode_filter>[0]<test-list>.ast !! Nil),
        :content_switch($<content_switch> ?? $<content_switch>[0]<test-list>.ast !! Nil),
        :attributes($<dtml-attribute>».ast),
        :start-position($/.from),
        :end-position($/.to),
    );
}

method dtml-attribute($/) {
    make DTML::AST::Attribute.new(
        :name($<name>.ast),
        :value($<value> ?? $<value>.Str !! Nil)
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml-entity-attribute($/) {
    make DTML::AST::Attribute.new(
        :name($<name>.Str),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml:sym<comment>($/) {
    make DTML::AST::Comment.new(
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml-declaration($/) {
    make DTML::AST::Declaration.new(
        :name($<name>.ast),
        :expression($<value-word>
            ?? DTML::AST::Expression.new(:word($<value-word>.ast))
            !! DTML::AST::Expression.new(:expression($<test-list>.ast))
        ),
        :start-position($/.from),
        :end-position($/.to),
    )
}

method dtml-expression($/) {
    make $<word>
        ?? DTML::AST::Expression.new(
            :word($<word>.ast)
            :start-position($/.from),
            :end-position($/.to),
        )
        !! DTML::AST::Expression.new(
            :expression($<test-list>.ast)
            :start-position($/.from),
            :end-position($/.to),
        )
}

method word($/) {
    make $/.Str
}
