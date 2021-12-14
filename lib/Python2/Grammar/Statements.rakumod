grammar Python2::Grammar::Statements {
    rule statement {
        | <variable-assignment>
        | <statement-print>
        | <expression>
        | <statement-loop-for>
        | <statement-if>
        | <function-definition>
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
        'if' <expression> ':' <suite>
    }

    rule variable-assignment {
        <variable-name> '=' <expression>
    }

    rule function-definition {
        'def' <function-name> '(' <function-definition-argument-list> ')' ':'
        <suite>
    }

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
