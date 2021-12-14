grammar Python2::Grammar::Expressions {
    rule expression {
        | <function-call>
        | <arithmetic-operation>
        | <literal>
        | <variable-access>
        | <list-definition>
        | <dictionary-definition>
    }


    # literals
    rule literal {
        | "'" <string> "'"
        | '"' <string> '"'
        | <number>
    }


    # arithmetic
    rule arithmetic-operation {
        <number> <arithmetic-operator> <number>
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


    # list handling
    rule list-definition {
        '['  <expression-list> ']'
    }

    rule expression-list {
        <expression>* %% ','
    }


    # dictionary handling
    rule dictionary-definition {
        '{'  <dictionary-entry-list> '}'
    }

    rule dictionary-entry-list {
        <dictionary-entry>* %% ','
    }

    rule dictionary-entry {
        <dictionary-key> ':' <expression>
    }

    # function call
    rule function-call {
        <function-name> '(' <function-call-argument-list> ')'
    }

    rule function-call-argument-list {
        <expression>* %% ','
    }

    token function-name     { <lower>+ }


    # basic, reused, tokens
    # TODO migrate to dedicated module
    token string            { [\w|\s]+ }
    token number            {
        | <float>
        | <integer>
    }
    token float             { \d+\.\d+ }
    token integer           { \d+ }
    token variable-name     { <lower>+ }
    token dictionary-key    {
        | <integer>+
        | "'" <string> "'"
        | '"' <string> '"'
    }
}
