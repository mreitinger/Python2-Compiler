role Python2::Grammar::Statements {
    token statement {
        [
            | <function-definition>
            | <statement-try-except>
            | <variable-assignment>
            | <instance-variable-assignment>
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
        'print' <.ws> <test>
    }

    token statement-return {
        | 'return' <.ws> <expression>
    }

    token statement-loop-for {
        'for' <.ws> <name> <.ws> 'in' <.ws> <expression> ':' <block>
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
        <or_test> [ <.ws> 'if' <.ws> <or_test> <.ws> 'else' <.ws> <test> ]?
    }

    token or_test {
        <and_test>  [<.ws> 'or' <.ws> <and_test> ]?
    }

    token and_test {
        <not_test> [ <.ws> 'and' <.ws> <not_test> ]?
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

    # power ain't right here it would allow too much in the future like
    # '(a if 1 else b) = 3'. not sure if we can prevent this here of if we do some post
    # processing?
    token variable-assignment {
        <power> <.ws> '=' <.ws> <test>
    }

    # we can't use object-access directly since we need access to the last element so
    # it can be passed to setvar()
    token instance-variable-assignment {
       <name> <object-access-operation>+ <list-or-dict-element>? <.ws> '=' <.ws> <expression>
    }

    token list-or-dict-element {
        '[' <literal> ']'
    }

    token function-definition {
        'def' <.ws> <name> '(' <function-definition-argument-list> ')' ':' <block>
    }

    token class-definition {
        'class' <.ws> <name> ':' <block>
    }

    token function-definition-argument-list {
        <name>* %% <list-delimiter>
    }
}
