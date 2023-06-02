use v6.e.PREVIEW;

use Python2::Grammar::Statements;
use Python2::Grammar::Expressions;
use Python2::Grammar::Common;
use Python2::ParseFail;

#use Grammar::Tracer;

package Python2::Grammar {
    grammar Complete
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

            # $*WHITE-SPACE this get's changed to \s+ when required for example when handling argument lists
            # tokens statement and block resets it back to rx/[\h|"\\\n"]/
            :my $*WHITE-SPACE = rx/[\h|"\\\n"]/;

            [
                || <non-code>
                || <level><statement>
            ]*

            \n* #match empty lines at the end
        }

        regex ws { die("Use <dws> for dynamic whitespace instead.") }

        regex dws { $*WHITE-SPACE }

        # a list of statements at the next indentation level
        token block {
            { $*WHITE-SPACE = rx/[\h|"\\\n"]/; }

            <scope-increase>
            <non-code>*
            <level><statement>
            [
                || <non-code>
                || <level><statement>
            ]*

            <scope-decrease>
        }

        # a block or statement
        token blorst {
            <block>
            | <.dws>* <statement>
        }

        token non-code {
            || <comment>
            || <.empty-lines>
        }

        token level { ' ' ** {@*levels[*-1]} }

        token scope-increase {
            :my $pos;
            <.non-code>+ # takes care of all whitespace before the scope increase - including \n
            <?before <level> \h+ {$pos = $/.pos;}>
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
            { @*levels.pop }
            :my @indentations = @*levels.map:{' ' x $_};
            [$ || <?before @indentations\N>]
        }
    }

    # Grammar restricted to a single expression
    grammar ExpressionsOnly
        does Python2::Grammar::Expressions
        does Python2::Grammar::Common
    {
        # $*WHITE-SPACE this get's changed to \s+ when required for example when handling argument lists
        # tokens statement and block resets it back to rx/[\h|"\\\n"]/
        token TOP {
            :my $*WHITE-SPACE = rx/[\h|"\\\n"]/;
            \s* # allow leading whitespace
            <test>
            \s* # allow trailing whitespace
        }

        # handled by Python2::Compiler
        method parse-fail (Int :$pos, Str :$what) {
            Python2::ParseFail.new(:$pos, :$what).throw();
        }

        regex ws { die("Use <dws> for dynamic whitespace instead.") }

        regex dws { $*WHITE-SPACE }
    }

}
