use Python2::Grammar::Statements;
use Python2::Grammar::Expressions;

#use Grammar::Tracer;


# in most places this Grammar is limited on purpose until the tests cover more
grammar Python2::Grammar
    is Python2::Grammar::Statements
    is Python2::Grammar::Expressions
{
    my $level = 0;
    my $end_of_last_statement = 0;
    my $indent_size = 4; # hack: python supports variable indent size

    token TOP {
        [
            || <comment>
            || <empty-line-at-same-scope>
            || <empty-line-scope-change>
            || <statement>
        ]+

        \n* #match empty lines at the end
    }

    # a list of statements at the next indentation level
    # TODO scope-increase should be handled like decrease: the previous match should
    # TODO know that it needs a scope increase and fail otherweise
    token block {
        <scope-increase>
        [
            || <empty-line-at-same-scope>
            || <statement>
        ]+

        # scope might decrease after the block is complete
        <empty-line-scope-change>?
    }

    token level { ' ' ** {$level} }

    token scope-increase {
        :my $pos;
        \n <?before <level> \h+ {$pos = $/.pos;}>
        {#`(need this empty code block to reset position)}
        { $level = $pos - $/.pos; }
    }

    # an empty line where the next statement is at the same scope
    token empty-line-at-same-scope {
        # we start checking at the beginning of the might-be-empty line
        [\h*\n]+             # we expect nothing except whitespace and newlines
        <?before ' ' ** {$level} \N>  # followed by something at the current indentation level
    }


    token empty-line-scope-change {
        <scope-decrease>+
    }

    method scope-decrease-one-level {
        self.debug('checking for scope-decrease-one-level');

        # current position of the parser
        my $pos = self.pos;

        # the complete input
        my $string = self.orig;

        my $expected_next_level = ($level - $indent_size) > 0 ?? ($level - $indent_size) !! 0;

        if (self.postmatch ~~ /
            ^
            \h ** {$expected_next_level}
            \H
        /) {
            $level = $expected_next_level;
            Match.new(:orig("scope-decrease-one-level"), :from(self.pos), :pos(self.pos));
        } else {
            self.FAILGOAL("");
        }
    }

    # an empty line where the next statement is at a lower scope/indentation level.
    # TODO handles only one line for now
    method scope-decrease {
        # current position of the parser
        my $pos = self.pos;

        # the complete input
        my $string = self.orig;

        self.debug('checking for empty line with scope change start');

        if (
            $string ~~ /
                ^
                . ** {$pos-1}
                (\n)
                (\n)
            /
        ) {
            my $remaining = $level - $indent_size;

            if ($remaining > 0) {
                $level = $remaining;

                Match.new(:orig("scope-decrease"), :from($1.from-2), :pos($1.pos-2));
            } elsif ($remaining == 0) {
                $level = $remaining;
                return $1;
            } else {
                self.FAILGOAL("");
            }
        }
        else {
            self.FAILGOAL("");
        }
    }

    token comment {
        '#' \N+ "\n"?
    }

    # TODO use command line parameter
    method debug ($caller) {
        return;
        my $string = self.orig;
        my $pos = self.pos;
        use Data::Dump;
        note "\n----------\n" ~ "$caller at $pos\n"
            ~ $string.substr(0, $pos)
            ~ "!!"
            ~ $string.substr($pos)
            #~ Dump(self) ~
            ~ "\n----------\n";
    }
}
