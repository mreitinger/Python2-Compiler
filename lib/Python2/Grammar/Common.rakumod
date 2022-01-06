role Python2::Grammar::Common {
    token class-name        { <lower>+ }
    token function-name     { [<lower>|<upper>|<digit>|_]+ }
    token variable-name     { [<lower>|<upper>|_][<lower>|<upper>|<digit>|_]* }

    # match the comma used in lists (actual Lists and Argument defintions) including
    # optional whitespace around it
    token list-delimiter { <.ws> ',' <.ws> }
}