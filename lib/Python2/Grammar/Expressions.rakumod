grammar Python2::Grammar::Expressions {
    rule expression {
        | <literal>
    }

    rule literal {
        | "'" <string> "'"
        | <integer>
    }

    token string    { \w }
    token integer   { \d }
}
