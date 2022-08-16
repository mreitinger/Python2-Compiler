role Python2::Grammar::Expressions {
    token expression {
        <xor-expression> [ <.ws> <or-expression-operator> <.ws> <xor-expression> ]*
    }

    token or-expression-operator { '|' }

    token xor-expression {
        <and-expression> [ <.ws> <xor-expression-operator> <.ws> <and-expression> ]*
    }

    token xor-expression-operator { '^' }

    token and-expression {
        <shift-expression> [ <.ws> <and-expression-operator> <.ws> <shift-expression> ]*
    }

    token and-expression-operator { '&' }

    token shift-expression {
        <arithmetic-expression-low-precedence> [ <.ws> <shift-expression-operator> <.ws> <arithmetic-expression-low-precedence> ]*
    }

    token shift-expression-operator { '<<' | '>>' }

    # literals
    token literal {
        | <string>
        | <number>
    }

    token argument-list {
        '('<.ews>
            <argument>* %% <extended-list-delimiter>
        [ <.ews> ')' || <parse-fail(:pos(self.pos), :what('expected )'))> ]
    }

    token argument {
        || <name> <.ws> '=' <.ws> <test>
        || <test>
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

    token list-comprehension {
        <expression> <.ws> 'for' <.ws> <name> <.ws> 'in' <.ws> <test> [<.ws> 'if' <.ws> <test>]?
    }


    # dictionary handling
    token dictionary-entry-list {
        <dictionary-entry>* %% <list-delimiter>
    }

    token dictionary-entry {
        <.ws> <test> <.ws> ':' <.ws> <test> <.ws>
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
        | <string-prefix><single-quoted-string>
        | <string-prefix><double-quoted-string>
        | <single-quoted-string>
        | <double-quoted-string>
        | <triple-single-quoted-string>
    }

    token string-prefix {
        | <string-prefix-raw>
        | <string-prefix-unicode>
    }

    token string-prefix-raw { 'r' }
    token string-prefix-unicode { 'u' }

    token triple-single-quoted-string   { "'''" <string-literal-triple-single-quoted> "'''" }
    token triple-double-quoted-string   { '"""' <string-literal-triple-double-quoted> '"""' }
    token single-quoted-string          { "'" <string-literal-single-quoted> "'" }
    token double-quoted-string          { '"' <string-literal-double-quoted> '"' }

    token string-literal-triple-single-quoted {
        (
            [
                | "\\'"         # escaped quote character
                | '\\'          # escaped literal backslash
                | <-['\\]>+   # everything except vertical whitespace, backslash and quote
            ]*
        )
    }

    token string-literal-triple-double-quoted {
        (
            [
                | '\\"'         # escaped quote character
                | '\\'          # escaped literal backslash
                | <-["\\]>+   # everything except vertical whitespace, backslash and quote
            ]*
        )
    }

    token string-literal-single-quoted {
        (
            [
                | "\\'"         # escaped quote character
                | '\\'          # escaped literal backslash
                | <-['\\\v]>+   # everything except vertical whitespace, backslash and quote
            ]*
        )
    }

    token string-literal-double-quoted {
        (
            [
                | '\\"'         # escaped quote character
                | '\\'          # escaped literal backslash
                | <-["\\\v]>+   # everything except vertical whitespace, backslash and quote
            ]*
        )
    }

    token number            {
        | <float>
        | <integer>
    }
    token float             { '-'? \d+\.\d+ }
    token integer           { '-'? \d+ }
}
