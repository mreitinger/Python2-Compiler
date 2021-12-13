use Python2::Grammar::Statements;
use Python2::Grammar::Expressions;

#use Grammar::Tracer;

# in most places this Grammar is limited on purpose until the tests cover more
grammar Python2::Grammar
    is Python2::Grammar::Statements
    is Python2::Grammar::Expressions
{
    rule TOP {
        [
            | <empty-line> ';'
            | <statement> ';'
            | <comment>
        ]+
    }

    token empty-line {
        \s*
    }

    token comment {
        '#' \N+
    }
}
