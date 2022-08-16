role Python2::Grammar::Statements {
    token statement {
        [
            | <function-definition>
            | <statement-try-except>
            | <variable-assignment>
            | <arithmetic-assignment>
            | <statement-print>
            | <statement-raise>
            | <statement-return>
            | <expression>
            | <statement-loop-for>
            | <statement-loop-while>
            | <statement-if>
            | <statement-with>
            | <class-definition>
            | <statement-import>
            | <statement-p5import>
        ]

        # ? to match EOF
        "\n"?
    }

    token statement-print {
        'print' <.ws> <test>
    }

    token statement-raise {
        'raise' <.ws> <test>
    }

    token statement-p5import {
        'p5import' <.ws> <perl5-package-name> <.ws> 'as' <.ws> <name>
    }

    token statement-import {
        'import' <.ws> <name>
    }

    # TODO p5 probably permits more here
    token perl5-package-name {
        [<lower>|<upper>|<digit>|_|\:]+
    }

    token statement-return {
        | 'return' [\h+ <test-list>]?
    }

    token statement-loop-for {
        'for' <.ws> <name> [<.ws> ',' <.ws> <name>]* <.ws> 'in' <.ws> <expression> ':' <block>
    }

    token statement-loop-while {
        'while' <.ws> <test> <.ws> ':' <block>
    }

    token statement-if {
        'if' <.ws> <test> ':' <block>
        <statement-elif>*
        [<level> 'else' ':' <block>]?
    }

    token statement-with {
        'with' <.ws> <test> <.ws> 'as' <.ws> <name> <.ws> ':' <block>
    }

    token statement-elif {
        <level> 'elif' <.ws> <test>':' <block>
    }

    token statement-try-except {
        'try' ':' <block>
        <level> 'except' ':' <block>
        [<level> 'finally' ':' <block>]?
    }

    token test-list {
        <test>+ %% <list-delimiter>
    }

    token test {
        || <lambda-definition>
        || <or_test> [ <.ws> 'if' <.ws> <or_test> <.ws> 'else' <.ws> <test> ]?
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
    token comparison-operator:sym<==>   { <sym> }
    token comparison-operator:sym<!=>   { <sym> }
    # token comparison-operator:sym<\<\>> { <sym> } #NYI
    token comparison-operator:sym<\>>   { <sym> }
    token comparison-operator:sym<\<>   { <sym> }
    token comparison-operator:sym<\>=>  { <sym> }
    token comparison-operator:sym<\<=>  { <sym> }
    token comparison-operator:sym<is>   { <sym> }
    token comparison-operator:sym<in>   { <sym> }


    # power ain't right here it would allow too much in the future like
    # '(a if 1 else b) = 3'. not sure if we can prevent this here of if we do some post
    # processing?
    token variable-assignment {
        <power> <.ws> '=' <.ws> <test>
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
        '[' <literal> [':' <literal>]? ']'
    }

    token function-definition {
        'def' <.ws> <name> '(' <function-definition-argument-list> ')' ':' <block>
    }

    token class-definition {
        'class' <.ws> <name> ':' <block>
    }

    token function-definition-argument-list {
        <function-definition-argument>* %% <list-delimiter>
    }

    token function-definition-argument {
        <name> [<.ws> '=' <.ws> <test>]?
    }
}
