use DTML::AST;
use Python2::AST;
use Python2::Actions::Expressions;

unit class DTML::Actions
    does Python2::Actions::Expressions;

method TOP($/) {
    make DTML::AST::Template.new(
        :input($/.Str)
        :chunks($<chunk>».ast),
    );
}

method chunk($/) {
    make $<dtml> ?? $<dtml>.ast !! $<content>.ast;
}

method content($/) {
    make DTML::AST::Content.new(:content($/.Str));
}

method dtml:sym<var>($/) {
    make $<word>
        ?? DTML::AST::Var.new(:word($<word>.ast))
        !! $<dtml-expression><word>
            ?? DTML::AST::Var.new(:word($<dtml-expression><word>.ast))
            !! DTML::AST::Var.new(:expression($<dtml-expression><test-list>.ast))
}

method dtml:sym<if>($/) {
    make $<dtml-expression><word>
        ?? DTML::AST::If.new(:word($<dtml-expression><word>.ast), :chunks($<chunk>».ast))
        !! DTML::AST::If.new(:expression($<dtml-expression><test-list>.ast), :chunks($<chunk>».ast))
}

method word($/) {
    make $/.Str
}
