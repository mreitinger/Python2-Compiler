role Python2::Grammar::Expressions {
    token expression {
        <arithmetic-expression-low-precedence>
    }


    # literals
    token literal {
        | <string>
        | <number>
    }

    token argument-list {
        '('
            <test>* %% <list-delimiter>
        [ ')' || <parse-fail(:input(self.target), :pos(self.pos), :what(')'))> ]
    }

    # arithmetic expressions
    # Credit for the high/low-precedence grammar solution goes to Andrew Shitov
    # https://andrewshitov.com/2020/03/08/chapter-3-creating-a-calculator/
    token arithmetic-expression-low-precedence {
        <arithmetic-expression-high-precedence>+ %% <arithmetic-operator-low-precedence>
    }

    token arithmetic-expression-high-precedence {
        <power>+ %% <arithmetic-operator-high-precedence>
    }

    token arithmetic-operator-high-precedence {
        <.ws> ['*' | '/' | '%'] <.ws>
    }

    token arithmetic-operator-low-precedence  {
        <.ws> [|'+'|'-'] <.ws>
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


    # lambda definition
    token lambda-definition {
        'lambda' <.ws> <function-definition-argument-list> <.ws> ':' <.ws> <test>
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
