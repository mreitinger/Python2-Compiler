use v6.e.PREVIEW;
use Python2::Grammar::Expressions;
use Python2::ParseFail;

#use Grammar::Tracer;
#use Grammar::Debugger;

unit grammar DTML::Grammar
    does Python2::Grammar::Expressions;

# handled by Python2::Compiler
method parse-fail (Int :$pos, Str :$what) {
    Python2::ParseFail.new(:$pos, :$what).throw();
}

token TOP {
    <chunk>*
}

token chunk {
    || <dtml>
    || <include>
    || <content>
}

rule content {
    [
        || <-[\< \&]>+
        || '<' <!before 'dtml' | '/dtml'>
        || '&' <!before 'dtml' | 'include'>
    ]+
}

token include {
    '&include-' $<file>=<[\w . -]>+ ';'
}

proto token dtml { * }

token dtml:sym<var> {
    | [
        '<' <.ws> 'dtml-' <.ws> 'var' <.ws>
        <dtml-expression> <.ws>
        [
            || <dump=value-attribute('dump')>
            || <fmt=value-attribute('fmt')>
            || <size=value-attribute('size')>
            || <etc=value-attribute('etc')>
            || <remove_attributes=value-attribute('remove_attributes')>
            || <remove_tags=value-attribute('remove_tags')>
            || <tag_content_only=value-attribute('tag_content_only')>
            || <dtml-attribute>
        ]* % <.ws>
        <.ws> '>'
    ]
    | [
        '&dtml' <.ws>
        <dtml-entity-attributes>?
        '-' <.ws> <word> ';'
    ]
}

token dtml:sym<return> {
    '<' <.ws> 'dtml-' <.ws> 'return' <.ws>
    <dtml-expression> <.ws>
    <dtml-attribute>* % <.ws>
    <.ws> '>'
}

token dtml:sym<comment> {
    <.start-tag('comment')>
    [
        || <-[\<]>+
        || <dtml:sym<comment>>
        || '<' <!before '/dtml-comment'>
    ]+
    <.end-tag('comment')>
}

token dtml:sym<if> {
    <.start-tag('if')>
    <dtml-expression> <.ws>
    '>'
    $<then>=<chunk>*
    <dtml-elif>*
    [
        <.start-tag('else')> '>'
        $<else>=<chunk>*
    ]?
    <.end-tag('if')>
}

token dtml-elif {
    <.start-tag('elif')>
    <dtml-expression> <.ws>
    '>'
    <chunk>*
}

token dtml:sym<unless> {
    <.start-tag('unless')>
    <dtml-expression> <.ws>
    '>'
    $<then>=<chunk>*
    [
        <.start-tag('else')> '>'
        $<else>=<chunk>*
    ]?
    <.end-tag('unless')>
}

token dtml:sym<let> {
    <.start-tag('let')>
    <dtml-declaration>* % <.ws>
    <.ws> '>'
    <chunk>*
    <.end-tag('let')>
}

token dtml:sym<with> {
    <.start-tag('with')>
    <dtml-expression> <.ws>
    '>'
    <chunk>*
    <.end-tag('with')>
}

token dtml:sym<in> {
    <.start-tag('in')>
    <dtml-expression> <.ws>
    [
        || <reverse=value-attribute('reverse')>
        || <start=value-attribute('start')>
        || <end=value-attribute('end')>
        || <size=value-attribute('size')>
        || <dtml-attribute>
    ]* % <.ws>
    <.ws> '>'
    <chunk>*
    <.end-tag('in')>
}

token dtml:sym<call> {
    <.start-tag('call')>
    <dtml-expression> <.ws>
    '>'
}

token dtml:sym<try> {
    <.start-tag('try')>
    '>'
    <chunk>*
    <dtml-except>?
    <.end-tag('try')>
}

token dtml:sym<raise> {
    <.start-tag('raise')>
    '>'
    <content>
    <.end-tag('raise')>
}

token dtml:sym<zms> {
    <.start-tag('zms')>
        [
            || <id=value-attribute('id')>
            || <caption=value-attribute('caption')>
            || <class=value-attribute('class')>
            || <max_children=value-attribute('max_children')>
            || <obj=expression-attribute('obj')>
            || <level=expression-attribute('level')>
            || <activenode=expression-attribute('activenode')>
            || <treenode_filter=expression-attribute('treenode_filter')>
            || <content_switch=expression-attribute('content_switch')>
            || <dtml-attribute>
        ]* % <.ws>
    <.ws> '>'
}

token value-attribute($name) {
    $<name>=$name <.ws> '=' <.ws>
    [
        || $<value>=\d+
        || \" $<value>=<-["]>* \"
        || \' $<value>=<-[']>* \'
        || <value-word=word>
    ]
}

token expression-attribute($name) {
    $<name>=$name <.ws> '=' <.ws>
    [
        || <value-word=word>
        || \" <.ws> <test-list> \"
        || \' <.ws> <test-list> \'
    ]
}

token dtml-except {
    <.start-tag('except')>
    '>'
    <chunk>*
}

token dtml-declaration {
    <name=word> <.ws>
    '=' <.ws>
    [
        || <value-word=word>
        || \" <.ws> <test-list> \"
        || \' <.ws> <test-list> \'
    ]
}

token dtml-attribute {
    <name=word> <.ws>
    [
        '='
        [
            || \" $<value>=<-["]>* \"
            || \' $<value>=<-[']>* \'
            || <value=word>
        ]
    ]?
}

token dtml-entity-attributes {
    '.'
    <dtml-entity-attribute>* % '.'
}

token dtml-entity-attribute {
    $<name>=\w+
}

token dtml-expression {
    || ['expr' <.ws> '=']? \" <.ws> <test-list> <.ws> \"
    || ['expr' <.ws> '=']? \' <.ws> <test-list> <.ws> \'
    || <word>
}

token word {
    <[\w -]>+
}

token start-tag($tag) {
    '<' <.ws> 'dtml-' <.ws> $tag <.ws>
}

token end-tag($tag) {
    '</dtml-' <.ws> $tag <.ws> '>'
}

regex dws { \s }

token locals {
    'locals'
}
