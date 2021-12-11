grammar Python2::Grammar::Statements {
    rule statement {
        | <variable-assignment>
        | <statement-print>
        | <expression>
        | <statement-loop-for>
    }

    # TODO: we need a intermediate step here like python's test/testlist
    rule statement-print {
        | 'print' <function-call>
        | 'print' <expression>
    }

    rule statement-loop-for {
        'for' <variable-name> 'in' <iterable> ':' <suite>
    }

    token iterable {
        | <list-definition>
        | <variable-access>
    }

    rule variable-assignment {
        <variable-name> '=' <expression>
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
