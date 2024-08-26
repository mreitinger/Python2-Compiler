role Python2::Grammar::Expressions {
    token expression {
        <xor-expression> [ <.dws>* <or-expression-operator> <.dws>* <xor-expression> ]*
    }

    token or-expression-operator { '|' }

    token xor-expression {
        <and-expression> [ <.dws>* <xor-expression-operator> <.dws>* <and-expression> ]*
    }

    token xor-expression-operator { '^' }

    token and-expression {
        <shift-expression> [ <.dws>* <and-expression-operator> <.dws>* <shift-expression> ]*
    }

    token and-expression-operator { '&' }

    token shift-expression {
        <arithmetic-expression-low-precedence> [ <.dws>* <shift-expression-operator> <.dws>* <arithmetic-expression-low-precedence> ]*
    }

    token shift-expression-operator { '<<' | '>>' }

    token argument-list {
        :my $*WHITE-SPACE = rx/[\s|"\\\n"|<comment>]/;

        '('
            <.dws>*
            <argument>* %% <list-delimiter>
            [ <.dws>* ')' || <parse-fail(:pos(self.pos), :what('expected )'))> ]
    }

    token argument {
        || <list-comprehension>
        || <name> <.dws>* '=' <.dws>* <test>
        || <splat>? <test>
    }

    token splat {
        '*'
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
        <.dws>* <high-precedence-operator> <.dws>*
    }

    token arithmetic-operator-low-precedence  {
        <.dws>* <low-precedence-operator> <.dws>*
    }

    token low-precedence-operator {
        | '+'
        | '-'
    }

    token high-precedence-operator {
        | '*'
        | '/'
        | '%'
    }

    token power {
        <atom> <trailer>*
    }

    token atom {
        | '(' <extended-test-list>    ')'
        | '[' <expression-list>       ']'
        | '[' <list-comprehension>    ']'
        | '{' <dictionary-entry-list> '}'
        | '{' <dict-comprehension>    '}'
        | '{' <set-entry-list>        '}'
        | <locals>
        | <name>
        | <number>
        | <string>
    }

    token trailer {
        || <.dws>* <argument-list>    # handles ('x')
        || <.dws>* <subscript>        # handles ['x']
        || <.dws>* '.' <.dws>* <name>   # handles .foo
    }

    token subscript {
        '['
            <.dws>*
            [
                || <start-slice>
                || <full-slice>
                || <end-slice>
                || <test>
            ]
            <.dws>*
        ']'
    }

    token full-slice {
        <test> <.dws>* ':' <.dws>* <test>
    }

    token start-slice {
        ':' <.dws>* <test>
    }

    token end-slice {
        <test> <.dws>* ':'
    }

    # access to a single variable
    token variable-access {
        | <object-access>
        | <name>
    }


    # list handling
    token expression-list {
        :my $*WHITE-SPACE = rx/[\s|"\\\n"|<comment>]/;
        <.dws>*
        <expression>* %% <list-delimiter>
        <.dws>*
    }

    token list-comprehension {
        :my $*WHITE-SPACE = rx/[\s|"\\\n"|<comment>]/;
        <.dws>*
        <test> <.dws>+ 'for' <.dws>+ <name> <.dws> 'in' <.dws>+ <test> [<.dws>+ 'if' <.dws>+ <test>]?
        <.dws>*
    }


    # dictionary handling
    token dictionary-entry-list {
        :my $*WHITE-SPACE = rx/[\s|"\\\n"|<comment>]/;
        <dictionary-entry>* %% <list-delimiter>
    }

    token dictionary-entry {
        <.dws>* <test> <.dws>* ':' <.dws>* <test> <.dws>*
    }

    token dict-comprehension {
        :my $*WHITE-SPACE = rx/[\s|"\\\n"|<comment>]/;
        <.dws>*
        <key=.test> <.dws>* ':' <.dws>* <value=.test> <.dws>+
        'for' <.dws>+ <name>+ % <list-delimiter> <.dws>
        'in' <.dws>+ <iterable=.test>
        [<.dws>+ 'if' <.dws>+ <condition=.test>]?
        <.dws>*
    }


    # set handling
    token set-entry-list {
        :my $*WHITE-SPACE = rx/[\s|"\\\n"|<comment>]/;
        <set-entry>* %% <list-delimiter>
    }

    token set-entry {
        <.dws>* <test> <.dws>*
    }

    # Match the comma used in lists (actual Lists and Argument defintions) including
    # optional whitespace around it.
    token list-delimiter { <.dws>* ',' <.dws>* }

    # Match function/variable/class names. Matches the NAME token in Python's grammar.
    token name  { [<lower>|<upper>|_][<lower>|<upper>|<digit>|_]* }

    # lambda definition
    token lambda-definition {
        'lambda' <.dws>+ <function-definition-argument-list> <.dws>* ':' <.dws>+ <test>
    }

    # string machting including escaped quotes
    # currently we don't allow any other escape sequences
    token string {
        | <string-prefix><triple-single-quoted-string>
        | <string-prefix><triple-double-quoted-string>
        | <string-prefix><single-quoted-string>
        | <string-prefix><double-quoted-string>
        | <triple-single-quoted-string>
        | <triple-double-quoted-string>
        | <single-quoted-string>
        | <double-quoted-string>
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
                | "'"  <-[']>    # single-single quotes within triple quoted strings
                | "''" <-[']>    # double-single quotes within triple quoted strings
                | "\\'"                 # escaped quote character
                | '\\'                  # escaped literal backslash
                | <-['\\]>              # everything except backslash and quote
            ]*
        )
    }

    token string-literal-triple-double-quoted {
        (
            [
                | '"' <-["]>    # single-double quotes within triple quoted strings
                | '""' <-["]>   # double-double quotes within triple quoted strings
                | '\\"'                # escaped quote character
                | '\\'                 # escaped literal backslash
                | <-["\\]>             # everything except backslash and quote
            ]*
        )
    }

    token string-literal-single-quoted {
        (
            [
                | "\\'"         # escaped quote character
                | '\\'          # escaped literal backslash
                | '\\'\n        # line continuation, filtered out later by the Actions
                | <-['\\\v]>+   # everything except vertical whitespace, backslash and quote
            ]*
        )
    }

    token string-literal-double-quoted {
        (
            [
                | '\\"'         # escaped quote character
                | '\\'          # escaped literal backslash
                | '\\'\n        # line continuation, filtered out later by the Actions
                | <-["\\\v]>+   # everything except vertical whitespace, backslash and quote
            ]*
        )
    }

    token test-list {
        <test>+ % <list-delimiter>
        <trailing-comma=.list-delimiter>?
    }

    token test {
        | <lambda-definition>
        | <left=.or_test> [ <.dws>+ 'if' <.dws>+ <condition=.or_test> <.dws>+ 'else' <.dws>+ <right=.test> ]?
    }

    token or_test {
        <and_test> [ <.dws>+ 'or' <.dws>+ <and_test> ]*
    }

    token and_test {
        <not_test> [ <.dws>+ 'and' <.dws>+ <not_test> ]*
    }

    token not_test {
        | 'not' <.dws>+ <not_test>
        | <comparison>
    }

    token comparison {
        <expression> [<.dws>* <comparison-operator> <.dws>* <expression>]*
    }

    token function-definition-argument-list {
        <function-definition-argument>* %% <list-delimiter>
    }

    token function-definition-argument {
        <splat>? <name> [<.dws>* '=' <.dws>* <test>]?
    }

    token extended-test-list {
        :my $*WHITE-SPACE = rx/[\s|"\\\n"|<comment>]/;
        <.dws>*
        <test>* % <list-delimiter>
        <trailing-comma=.list-delimiter>?
        <.dws>*
    }

    token comparison-operator {
        |  '=='
        |  '!='
        |  '>='
        |  '<='
        |  '>'
        |  '<'
        |  'is not'
        |  'is'
        |  'in'
        |  'not in'
    }

    token number            {
        | <float>
        | <integer>
    }
    token float             { ['-'|'+'] ? \d*\.\d+ }
    token integer           { ['-'|'+'] ? \d+ }
}
