grammar Python2::Grammar::Expressions {
    rule expression {
        | <literal>
    }

    rule literal {
        "'" <string> "'"
    }

    token string { \w }
}
