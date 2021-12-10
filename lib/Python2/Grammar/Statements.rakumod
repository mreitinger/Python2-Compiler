grammar Python2::Grammar::Statements {
    rule statement {
        | <variable-assignment>
        | <statement-print>
        | <expression>
    }

    rule statement-print {
        'print' <expression>
    }

    rule variable-assignment {
        <variable-name> '=' <expression>
    }
}
