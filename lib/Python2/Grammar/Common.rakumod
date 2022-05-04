role Python2::Grammar::Common {
    # Match function/variable/class names. Matches the NAME token in Python's grammar.
    token name  { [<lower>|<upper>|_][<lower>|<upper>|<digit>|_]* }

    # Match the comma used in lists (actual Lists and Argument defintions) including
    # optional whitespace around it.
    token list-delimiter { <.ws> ',' <.ws> }

    token atom {
        | '(' <.ws> <test-list> <.ws> ')'
        | '[' <.ws> <expression-list> <.ws> ']'
        | '{' <.ws> <dictionary-entry-list> <.ws> '}'
        | <name>
        | <number>
        | <string>
    }

    token power {
        <atom> <trailer>*
    }

    token trailer {
        | <argument-list>   # handles ('x')
        | <subscript>       # handles ['x']
        | '.' <name>        # handles .foo
    }

    token subscript { '[' <literal> [':' <literal>]? ']' }
}