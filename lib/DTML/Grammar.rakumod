use Python2::Grammar::Expressions;

unit grammar DTML::Grammar
    does Python2::Grammar::Expressions;

token TOP {
    <chunk>*
}

token chunk {
    || <dtml>
    || <content>
}

rule content {
    [
        || <-[\< \&]>+
        || '<' <!before 'dtml' | '/dtml'>
        || '&' <!before 'dtml' | '/dtml'>
    ]+
}

proto token dtml { * }

token dtml:sym<var> {
    | [
        '<' <.ws> 'dtml-' <.ws> 'var' <.ws>
        <dtml-expression> <.ws>
        '>'
    ]
    | [
        '&dtml' <.ws> '-' <.ws> <word> ';'
    ]
}

token dtml:sym<if> {
    '<' <.ws> 'dtml-' <.ws> 'if' <.ws>
    <dtml-expression> <.ws>
    '>'
    <chunk>*
    '</dtml-if>'
}

token dtml-expression {
    || \" <test-list> \"
    || \' <test-list> \'
    || <word>
}

token word {
    <[\w -]>+
}

regex dws { \s }

token locals {
    'locals'
}
