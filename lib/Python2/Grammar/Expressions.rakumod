role Python2::Grammar::Expressions {
    token expression {
        | <function-call>

        | <arithmetic-operation>
        || <literal>

        | <variable-access>
        | <list-definition>
        | <dictionary-definition>
    }


    # literals
    token literal {
        | <string>
        | <number>
    }


    # arithmetic
    rule arithmetic-operation {
        <operand> [<arithmetic-operator> <operand>]+
    }

    token operand {
        | <number>
        | <variable-access>
    }

    token arithmetic-operator {
        [
            | '+'
            | '-'
            | '*'
            | '/'
        ]
    }

    # access to a single variable
    token variable-access {
        | <object-access>
        | <dictionary-access>
        | <variable-name>
    }

    token dictionary-access {
        <variable-name> '[' <literal> ']'
    }


    # list handling
    token list-definition {
        '[' <.ws> <expression-list> <.ws> ']'
    }

    token expression-list {
        <expression>* %% <list-delimiter>
    }


    # dictionary handling
    token dictionary-definition {
        '{' <.ws> <dictionary-entry-list> <.ws> '}'
    }

    token dictionary-entry-list {
        <dictionary-entry>* %% <list-delimiter>
    }

    token dictionary-entry {
        <.ws> <dictionary-key> <.ws> ':' <.ws> <expression> <.ws>
    }

    # function call
    token function-call {
        <function-name> '(' <function-call-argument-list> ')'
    }

    token function-call-argument-list {
        <expression>* %% <list-delimiter>
    }

    token function-name     { [<lower>|<upper>|<digit>|_]+ }


    # access to object instance variables and methods
    token object-access {
        <variable-name> <object-access-operation>+
    }

    token object-access-operation {
        || <method-call>
        || <instance-variable-access>
    }

    token method-call {
        '.' <function-name> '(' <function-call-argument-list> ')'
    }

    # access to a instance variable
    token instance-variable-access {
        '.' <variable-name>
    }


    # basic, reused, tokens
    # TODO migrate to dedicated module

    # string machting including escaped quotes
    # currently we don't allow any other escape sequences
    token string {
        | "'" (<string-literal>) "'"
        | '"' (<string-literal>) '"'
    }

    token string-literal {
        (
            [
                | "\\'"        # escaped quote character
                | '\\"'        # escaped quote character
                | '\\'         # escaped literal backslash
                | <-['"\\\v]>+   # everything except vertical whitespace, backslash and quote
            ]*
        )
    }

    token number            {
        | <float>
        | <integer>
    }
    token float             { \d+\.\d+ }
    token integer           { \d+ }
    token variable-name     { [<lower>|<upper>|_][<lower>|<upper>|<digit>|_]* }
    token dictionary-key    {
        | <integer>+
        | <string>
    }
}
