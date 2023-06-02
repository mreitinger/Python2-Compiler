role Python2::Grammar::Common {
    # Match function/variable/class names. Matches the NAME token in Python's grammar.
    token name  { [<lower>|<upper>|_][<lower>|<upper>|<digit>|_]* }

    token locals {
        'locals'
    }

    # Match dotted_name in Python's grammar - used for module imports.
    token dotted-name  { <name> [ '.' <name> ]* }

    # Match the comma used in lists (actual Lists and Argument defintions) including
    # optional whitespace around it.
    token list-delimiter { <.dws>* ',' <.dws>* }

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

    token power {
        <atom> <trailer>*
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

    token comment {
        \h* '#' (\N*) "\n"?
    }
}
