grammar Python2::Grammar::Statements {
    token statement {
        [
            | <function-definition>
            | <statement-try-except>
            | <variable-assignment>
            | <statement-print>
            | <expression>
            | <statement-loop-for>
            | <statement-if>
            | <class-definition>
            | <statement-return>
        ]

        # ? to match EOF
        "\n"?
    }

    # TODO: we need a intermediate step here like python's test/testlist
    token statement-print {
        | 'print' <.ws> <function-call>
        | 'print' <.ws> <expression>
    }

    token statement-return {
        | 'return' <.ws> <expression>
    }

    token statement-loop-for {
        'for' <.ws> <variable-name> <.ws> 'in' <.ws> <expression> ':' <block>
    }

    token statement-if {
        'if' <.ws> <test> ':' <block>
        [<level> 'else' ':' <block>]?
    }

    token statement-try-except {
        # a block gets terminated with a trailing semicolon. capture it here to prevent
        # our grammer from starting a new statement.
        'try' ':' <block>
        <level> 'except' ':' <block>
        [<level> 'finally' ':' <block>]?
    }

    token test {
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

    token variable-assignment {
        <variable-name> <.ws> '=' <.ws> <expression>
    }

    token function-definition {
        'def' <.ws> <function-name> '(' <function-definition-argument-list> ')' ':' <block>
    }

    token class-definition {
        'class' <.ws> <class-name> ':' <block>
    }

    token class-name     { <lower>+ }

    token function-definition-argument-list {
        <variable-name>* %% <list-delimiter>
    }

    token list-delimiter {
        <.ws> ',' <.ws>
    }
}
