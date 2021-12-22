grammar Python2::Grammar::Statements {
    rule statement {
        | <statement-try-except>
        | <variable-assignment>
        | <statement-print>
        | <expression>
        | <statement-loop-for>
        | <statement-if>
        | <function-definition>
        | <class-definition>
    }

    # TODO: we need a intermediate step here like python's test/testlist
    rule statement-print {
        | 'print' <function-call>
        | 'print' <expression>
    }

    rule statement-loop-for {
        'for' <variable-name> 'in' <expression> ':' <suite>
    }

    rule statement-if {
        'if' <test> ':' <suite>
    }

    rule statement-try-except {
        # a suite gets terminated with a trailing semicolon. capture it here to prevent
        # our grammer from starting a new statement.
        'try' ':' <suite> ';' 'except' ':' <suite>
    }

    rule test {
        | <expression> <comparison-operator> <expression>
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

    rule variable-assignment {
        <variable-name> '=' <expression>
    }

    rule function-definition {
        'def' <function-name> '(' <function-definition-argument-list> ')' ':'
        <suite>
    }

    rule class-definition {
        'class' <class-name> ':' <suite>
    }

    token class-name     { <lower>+ }

    rule function-definition-argument-list {
        <variable-name>* %% ','
    }

    # TODO migrate to a dedicated Grammer::X module with other 'groupings'
    # TODO why does python call this a 'suite'?
    # TODO this only handles blocks not a single statement like 'for x in y: statement'
    rule suite {
        '{'
            <statement>* %% ';'
        '}'
    }
}
