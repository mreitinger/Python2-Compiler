role Python2::Grammar::Statements {
    # handles comments after statements - they already handle \n etc so we have a dedicated
    # token for that
    token end-of-line-comment {
        '#' (\N+)
    }

    token end-of-statement {
        \h*
        <end-of-line-comment>?
        ["\n"|';'|$]
    }


    token statement {
        ||  [
                [
                    | <statement-return>
                    | <statement-with>
                    | <function-definition>
                    | <statement-try-except>
                    | <statement-print>
                    | <statement-raise>
                    | <statement-break>
                    | <statement-loop-for>
                    | <statement-loop-while>
                    | <statement-if>
                    | <class-definition>
                    | <statement-import>
                    | <statement-p5import>
                    | <statement-from>
                    | <statement-del>
                    | <statement-assert>
                    | <statement-pass>
                    | <statement-continue>
                ]
            ]
        ||  [
                [
                    || <variable-assignment>
                    || <arithmetic-assignment>
                    || <expression>
                ]
                <.end-of-statement>
            ]
    }

    token statement-pass {
        'pass'
        <.end-of-statement>
    }

    token statement-continue {
        'continue'
        <.end-of-line-comment>?
        ["\n"|';'|$]
    }

    token statement-print {
        'print' <.dws>* <test>
        <.end-of-statement>
    }

    token statement-raise {
        'raise' \h+ <test> [<.dws>* ','<.dws>* <test>]?
        <.end-of-statement>
    }

    token statement-p5import {
        'p5import' <.dws>+ <perl5-package-name> <.dws>+ 'as' <.dws>+ <name>
        <.end-of-statement>
    }

    token statement-import {
        'import' <.dws>+ <dotted-name> [<.dws>+ 'as' <.dws>+ <name>]?
        <.end-of-statement>
    }

    token statement-from {
        'from' <.dws>+ <dotted-name> <.dws>+ 'import' <.dws>+ <import-names>
        <.end-of-statement>
    }

    token import-names {
        <name>+ %% <list-delimiter>
    }

    token statement-del {
        'del' <.dws>+ <name>
        <.end-of-statement>
    }

    token statement-assert {
        'assert' <.dws>+ <test> [<.dws>* ',' <.dws>* <test>]?
        <.end-of-statement>
    }

    # TODO p5 probably permits more here
    token perl5-package-name {
        [<lower>|<upper>|<digit>|_|\:]+
    }

    token statement-return {
        'return' [<.dws>+ <test-list>]?
        <.end-of-statement>
    }

    token statement-break {
        'break'
        <.end-of-statement>
    }

    token statement-loop-for {
        'for' <.dws>+ <name> [<.dws>* ',' <.dws>* <name>]* <.dws>+ 'in' <.dws>+ <expression> <.dws>*':' <block>
    }

    token statement-loop-while {
        'while' <.dws>+ <test> <.dws>* ':' <block>
    }

    token statement-if {
        'if' <.dws>+ <test> <.dws>* ':' <block>
        <statement-elif>*
        [<level> 'else' <.dws>* ':' <block>]?
    }

    token statement-with {
        'with' <.dws>+ <test> <.dws>+ 'as' <.dws>+ <name> <.dws>* ':' <block>
    }

    token statement-elif {
        <level> 'elif' <.dws>+ <test> <.dws>* ':' <block>
    }

    token statement-try-except {
        'try' <.dws>* ':' <block>
        <exception-clause>+
        [<level> 'finally' <.dws>* ':' <block>]?
    }

    # TODO python allowes <test> to determine the variable assignment/exception
    token exception-clause {
        <level> 'except' [<.dws>+ <name> [<.dws>* ',' <.dws>* <name>]?]? <.dws>* ':' <block>
    }

    token extended-test-list {
        :my $*WHITE-SPACE = rx/[\s|"\\\n"]/;
        <.dws>*
        <test>+ %% <list-delimiter>
        <.dws>*
    }

    token test-list {
        <test>+ %% <list-delimiter>
    }

    token test {
        | <lambda-definition>
        | <or_test> [ <.dws>+ 'if' <.dws>+ <or_test> <.dws>+ 'else' <.dws>+ <test> ]?
    }

    token or_test {
        <and_test> [ <.dws>+ 'or' <.dws>+ <and_test> ]*
    }

    token and_test {
        <not_test> [ <.dws>+ 'and' <.dws>+ <not_test> ]*
    }

    token not_test {
        | 'not' <.dws>+ <not_test>
        | <comparison>
    }

    token comparison {
        [
            | <expression> <.dws>* <comparison-operator> <.dws>* <expression>
            | <expression>
        ]
    }

    proto token comparison-operator {*}
    token comparison-operator:sym<==>       { <sym> }
    token comparison-operator:sym<!=>       { <sym> }
    # token comparison-operator:sym<\<\>>   { <sym> } #NYI
    token comparison-operator:sym<\>>       { <sym> }
    token comparison-operator:sym<\<>       { <sym> }
    token comparison-operator:sym<\>=>      { <sym> }
    token comparison-operator:sym<\<=>      { <sym> }
    token comparison-operator:sym<is>       { <sym> }
    token comparison-operator:sym<in>       { <sym> }
    token comparison-operator:sym<not-in>   { <not-in> }
    token not-in                            { 'not in' }

    # power ain't right here it would allow too much in the future like
    # '(a if 1 else b) = 3'. not sure if we can prevent this here of if we do some post
    # processing?
    token variable-assignment {
        <power> [ <.dws>* ',' <.dws>* <power>]*  <.dws>* '=' <.dws>* <test>
    }

    token arithmetic-assignment {
        <power> <.dws>* <arithmetic-assignment-operator>  <.dws>* <test>
    }

    proto token arithmetic-assignment-operator {*}
    token arithmetic-assignment-operator:sym<+=>    { <sym> }
    token arithmetic-assignment-operator:sym<-=>    { <sym> }
    token arithmetic-assignment-operator:sym<*=>    { <sym> }
    token arithmetic-assignment-operator:sym</=>    { <sym> }
    token arithmetic-assignment-operator:sym<%=>    { <sym> }
    token arithmetic-assignment-operator:sym<//=>   { <sym> }
    token arithmetic-assignment-operator:sym<**=>   { <sym> }
    token arithmetic-assignment-operator:sym<&=>    { <sym> }
    token arithmetic-assignment-operator:sym<|=>    { <sym> }
    token arithmetic-assignment-operator:sym<^=>    { <sym> }
    token arithmetic-assignment-operator:sym<\>\>=> { <sym> }
    token arithmetic-assignment-operator:sym<\<\<=> { <sym> }

    token list-or-dict-element {
        '[' <.dws>* <literal> [<.dws>* ':' <.dws>* <literal>]? <.dws>* ']'
    }

    token function-definition {
        'def' <.dws>+ <name> '(' <function-definition-argument-list> ')' <.dws>* ':' <block>
    }

    # inheritance is restricted to a single <name> for now - we don't support anything else at
    # this time.
    token class-definition {
        'class' <.dws>+ <name> [ '(' <.dws>* <name> <.dws>* ')' ]? <.dws>* ':' <block>
    }

    token function-definition-argument-list {
        <function-definition-argument>* %% <list-delimiter>
    }

    token function-definition-argument {
        <name> [<.dws>* '=' <.dws>* <test>]?
    }
}
