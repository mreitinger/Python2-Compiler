role Python2::Grammar::Common {
    # Match function/variable/class names. Matches the NAME token in Python's grammar.
    token name  { [<lower>|<upper>|_][<lower>|<upper>|<digit>|_]* }

    # Match dotted_name in Python's grammar - used for module imports.
    token dotted-name  { <name> [ '.' <name> ]* }

    # Match the comma used in lists (actual Lists and Argument defintions) including
    # optional whitespace around it.
    token list-delimiter { <.ws> ',' <.ws> }

    # 'extended' list delimiter - allow line continuation even without explicit \ at the end of line
    token extended-list-delimiter { <.ews> ',' <.ews> }

    token atom {
        | '(' <.ws> <test-list> <.ws> ')'
        | '[' <.ws> <expression-list> <.ws> ']'
        | '[' <.ws> <list-comprehension> <.ws> ']'
        | '{' <.ws> <dictionary-entry-list> <.ws> '}'
        | '{' <.ws> <set-entry-list> <.ws> '}'
        | <name>
        | <number>
        | <string>
    }

    token power {
        <atom> <trailer>*
    }

    token trailer {
        || <.ws> <argument-list>    # handles ('x')
        || <.ws> <subscript>        # handles ['x']
        || <.ws> '.' <.ws> <name>   # handles .foo
    }

    token subscript {
        '['
            <.ws>
            [
                || <start-slice>
                || <full-slice>
                || <end-slice>
                || <test>
            ]
            <.ws>
        ']'
    }

    token full-slice {
        <test> <.ws> ':' <.ws> <test>
    }

    token start-slice {
        ':' <.ws> <test>
    }

    token end-slice {
        <test> <.ws> ':'
    }
}