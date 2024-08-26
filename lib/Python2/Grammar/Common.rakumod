role Python2::Grammar::Common {

    token locals {
        'locals'
    }

    # Match dotted_name in Python's grammar - used for module imports.
    token dotted-name  { <name> [ '.' <name> ]* }

    token comment {
        \h* '#' (\N*) "\n"?
    }
}
