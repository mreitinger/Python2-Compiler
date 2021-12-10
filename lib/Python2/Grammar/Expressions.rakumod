grammar Python2::Grammar::Expressions {
    rule expression {
        | <arithmetic-operation>
        | <literal>
    }


    # literals
    rule literal {
        | "'" <string> "'"
        | <integer>
    }


    # arithmetic
    rule arithmetic-operation {
        <integer> <arithmetic-operator> <integer>
    }

    proto token arithmetic-operator {*}
    token arithmetic-operator:sym<+> { <sym> }
    token arithmetic-operator:sym<-> { <sym> }
    token arithmetic-operator:sym<*> { <sym> }
    token arithmetic-operator:sym</> { <sym> }


    # basic, reused, tokens
    token string    { \w }
    token integer   { \d }
}
