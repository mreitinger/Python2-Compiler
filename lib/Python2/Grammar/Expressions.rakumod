grammar Python2::Grammar::Expressions {
    rule expression {
        | <arithmetic-operation>
        | <literal>
        | <variable-access>
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


    # access to a single variable
    rule variable-access {
        <variable-name>
    }


    # basic, reused, tokens
    # TODO migrate to dedicated module
    token string        { \w }
    token integer       { \d }
    token variable-name { <lower>+ }
}
