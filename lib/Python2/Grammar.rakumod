use v6.e.PREVIEW;

use Python2::Grammar::Statements;
use Python2::Grammar::Expressions;
use Python2::Grammar::Common;
use Python2::ParseFail;

#use Grammar::Tracer;

# in most places this Grammar is limited on purpose until the tests cover more
grammar Python2::Grammar
    does Python2::Grammar::Statements
    does Python2::Grammar::Expressions
    does Python2::Grammar::Common
{
    # handled by Python2::Compiler
    method parse-fail (Int :$pos, Str :$what) {
        Python2::ParseFail.new(:$pos, :$what).throw();
    }

    token TOP {
        :my @*levels = (0);

        [
            || <non-code>
            || <level><statement>
        ]*

        \n* #match empty lines at the end
    }

    regex ws { <!ww> \s* "\\\n"? \s* }

    # 'extended' whitespace - allow line continuation even without explicit \ at the end of line
    # used within argument lists etc.
    regex ews { <!ww> \s* "\\?\n"? \s* }

    # a list of statements at the next indentation level
    token block {
        <scope-increase>
        <non-code>*
        <level><statement>
        [
            || <non-code>
            || <level><statement>
        ]*

        <scope-decrease>
    }

    token non-code {
        ||<comment>
        || <.empty-lines>
    }

    token level { ' ' ** {@*levels[*-1]} }

    token scope-increase {
        :my $pos;
        \n <?before <level> \h+ {$pos = $/.pos;}>
        {#`(need this empty code block to reset position)}
        { @*levels.push: $pos - $/.pos; }
    }

    # an empty line where the next statement is at the same scope
    token empty-lines {
        # we start checking at the beginning of the might-be-empty line
        [\h*\n]+             # we expect nothing except whitespace and newlines
    }

    token scope-decrease {
        [\h*\n]* # may have some "empty" lines
        :my @indentations = @*levels.map:{' ' x $_};
        [$ || <?before @indentations\N>]
        { @*levels.pop }
    }

    token comment {
        \h* '#' (\N+) "\n"?
    }
}
