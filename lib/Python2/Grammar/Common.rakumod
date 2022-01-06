role Python2::Grammar::Common {
    # Match function/variable/class names. Matches the NAME token in Python's grammar.
    token name  { [<lower>|<upper>|_][<lower>|<upper>|<digit>|_]* }

    # Match the comma used in lists (actual Lists and Argument defintions) including
    # optional whitespace around it.
    token list-delimiter { <.ws> ',' <.ws> }
}