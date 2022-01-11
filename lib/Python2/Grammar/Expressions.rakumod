role Python2::Grammar::Expressions {
    token expression {
        <arithmetic-operation>
    }


    # literals
    token literal {
        | <string>
        | <number>
    }

    token argument-list {
        '(' <test>* %% <list-delimiter> ')'
    }



    # arithmetic
    token arithmetic-operation {
        <power> [<.ws> <arithmetic-operator> <.ws> <power>]*
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
        | <name>
    }


    # list handling
    token expression-list {
        <expression>* %% <list-delimiter>
    }


    # dictionary handling
    token dictionary-entry-list {
        <dictionary-entry>* %% <list-delimiter>
    }

    token dictionary-entry {
        <.ws> <dictionary-key> <.ws> ':' <.ws> <expression> <.ws>
    }




    # access to object instance variables and methods
    token object-access {
        <name> <object-access-operation>+
    }

    token object-access-operation {
        <instance-variable-access>
    }

    # access to a instance variable
    token instance-variable-access {
        '.' <name>
    }


    # basic, reused, tokens
    # TODO migrate to dedicated module

    # string machting including escaped quotes
    # currently we don't allow any other escape sequences
    token string {
        | "'" <string-literal> "'"
        | '"' <string-literal> '"'
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
    token dictionary-key    {
        | <integer>+
        | <string>
    }
}
