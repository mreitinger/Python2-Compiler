grammar Python2::Grammar::Statements {
    rule statement {
        | <expression>
        | <statement-print>
    }

    rule statement-print {
        'print' <expression>
    }
}
