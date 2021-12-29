use Python2::Grammar::Statements;
use Python2::Grammar::Expressions;

#use Grammar::Tracer;


# in most places this Grammar is limited on purpose until the tests cover more
grammar Python2::Grammar
    is Python2::Grammar::Statements
    is Python2::Grammar::Expressions
{

    token TOP {
        :my @*levels = (0);

        [
            || <comment>
            || <empty-line-at-same-scope>
            || <level><statement>
        ]*

        \n* #match empty lines at the end
    }

    # a list of statements at the next indentation level
    token block {
        <scope-increase>
        <empty-line-at-same-scope>*
        <level><statement>
        [
            || <empty-line-at-same-scope>
            || <level><statement>
        ]*

        <scope-decrease>
    }

    token level { ' ' ** {@*levels[*-1]} }

    token scope-increase {
        :my $pos;
        \n <?before <level> \h+ {$pos = $/.pos;}>
        {#`(need this empty code block to reset position)}
        { @*levels.push: $pos - $/.pos; }
    }

    # an empty line where the next statement is at the same scope
    token empty-line-at-same-scope {
        # we start checking at the beginning of the might-be-empty line
        [\h*\n]+             # we expect nothing except whitespace and newlines
        <?before ' ' ** {@*levels[*-1]} \N>  # followed by something at the current indentation level
    }

    token scope-decrease {
        [\h*\n]* # may have some "empty" lines
        :my @indentations = @*levels.map:{' ' x $_};
        [$ || <?before @indentations\N>]
        { @*levels.pop }
    }

    token comment {
        '#' \N+ "\n"?
    }
}
