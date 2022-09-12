role Python2::Grammar::Statements {
    token statement {
        [
            || <statement-with>
            || <variable-assignment>
            | <function-definition>
            | <statement-try-except>
            | <arithmetic-assignment>
            | <statement-print>
            | <statement-raise>
            | <statement-return>
            | <statement-break>
            | <expression>
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
        ]

        # ? to match EOF
        ["\n"|';']?
    }

    token statement-pass {
        'pass'
    }

    token statement-print {
        'print' <.ws> <test>
    }

    token statement-raise {
        'raise' \h+ <test> [<.ws> ',' <.ws> <test>]?
    }

    token statement-p5import {
        'p5import' \h+ <perl5-package-name> \h+ 'as' \h+ <name>
    }

    token statement-import {
        'import' \h+ <name>
    }

    token statement-from {
        'from' \h+ <dotted-name> \h+ 'import' \h+ <import-names>
    }

    token import-names {
        <name>+ %% <list-delimiter>
    }

    token statement-del {
        'del' \h+ <name>
    }

    token statement-assert {
        'assert' \h+ <test> [<.ws> ',' <.ws> <test>]?
    }

    # TODO p5 probably permits more here
    token perl5-package-name {
        [<lower>|<upper>|<digit>|_|\:]+
    }

    token statement-return {
        | 'return' [\h+ <test-list>]?
    }

    token statement-break {
        | 'break'
    }

    token statement-loop-for {
        'for' \h+ <name> [<.ws> ',' <.ws> <name>]* \h+ 'in' \h+ <expression> ':' <block>
    }

    token statement-loop-while {
        'while' \h+ <test> <.ws> ':' <block>
    }

    token statement-if {
        'if' \h+ <test> <.ws> ':' <block>
        <statement-elif>*
        [<level> 'else' <.ws> ':' <block>]?
    }

    token statement-with {
        'with' \h+ <test> \h+ 'as' \h+ <name> <.ws> ':' <block>
    }

    token statement-elif {
        <level> 'elif' \h+ <test> <.ws> ':' <block>
    }

    token statement-try-except {
        'try' <.ws> ':' <block>
        <exception-clause>+
        [<level> 'finally' <.ws> ':' <block>]?
    }

    # TODO python allowes <test> to determine the variable assignment/exception
    token exception-clause {
        <level> 'except' [\h+ <name> [<.ws> ',' <.ws> <name>]?]? <.ws> ':' <block>
    }


    token test-list {
        <test>+ %% <list-delimiter>
    }

    token test {
        || <lambda-definition>
        || <or_test> [ \h+ 'if' \h+ <or_test> \h+ 'else' \h+ <test> ]?
    }

    token or_test {
        <and_test>  [<.ws> 'or' <.ws> <and_test> ]*
    }

    token and_test {
        <not_test> [ <.ws> 'and' <.ws> <not_test> ]*
    }

    token not_test {
        | 'not' <.ws> <not_test>
        | <comparison>
    }

    token comparison {
        | <expression> <.ws> <comparison-operator> <.ws> <expression>
        | <expression>
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
        <power> [<.ws> ',' <.ws> <power>]* <.ws> '=' <.ws> <test>
    }

    token arithmetic-assignment {
        <power> <.ws> <arithmetic-assignment-operator> <.ws> <test>
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
        '[' <.ws> <literal> [<.ws> ':' <.ws> <literal>]? <.ws> ']'
    }

    token function-definition {
        'def' \h+ <name> '(' <function-definition-argument-list> ')' <.ws> ':' <block>
    }

    # inheritance is restricted to a single <name> for now - we don't support anything else at
    # this time.
    token class-definition {
        'class' \h+ <name> [ '(' <.ws> <name> <.ws> ')' ]? <.ws> ':' <block>
    }

    token function-definition-argument-list {
        <function-definition-argument>* %% <list-delimiter>
    }

    token function-definition-argument {
        <name> [<.ws> '=' <.ws> <test>]?
    }
}
