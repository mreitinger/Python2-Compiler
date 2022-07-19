use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;
use Python2::Optimizer;
use Data::Dump;

class Python2::Compiler {
    has Bool $.optimize = True;
    has Bool $.dumpast  = False;
    has Str  $.embedded;

    has $!backend = Python2::Backend::Perl5.new(:$!embedded);
    has $!parser        = Python2::Grammar.new();
    has $!optimizer     = Python2::Optimizer.new();
    has $!actions       = Python2::Actions.new();

    method compile (Str $input) {
        my $ast = $!parser.parse($input, actions => $!actions);

        CATCH {
            # generic parser error
            when X::Syntax::Confused {
                self.parse-fail(:$input, :pos($_.pos));
            }

            # our custom exceptions
            when Python2::Grammar::ParseFail {
                self.parse-fail(:$input, :pos($_.pos), :what($_.what));
            }
        }

        my $root = $ast.made.clone;

        $!optimizer.t($root) if $.optimize;

        if ($.dumpast)  {
            note Dump($root, :no-postfix, :skip-methods);
            exit 0;
        }

        return $!backend.e($root);
    }

    method parse-fail(Str :$input, Int :$pos, Str :$what?) {
        my @input-as-lines          = $input.lines;
        my $failed-at-line          = $input.substr(0, $pos).lines.elems;

        my $failed-position-in-line =
            $failed-at-line > 1
            ??  # total position (in charaters) where the parser failed
                $pos

                # ignore all characters from preceeding lines
                - @input-as-lines[0 .. $failed-at-line - 2] .join.chars

                # ignore \n characters, except failing line
                - $failed-at-line + 1

            !! $pos;

        note "Parsing failed at line $failed-at-line:";
        note '';

        # output preceeding line, if present
        note sprintf("%5i | %s",
            $failed-at-line - 1,
            @input-as-lines[$failed-at-line - 2],
        ) if @input-as-lines[$failed-at-line - 2].defined;

        # output line with syntax error
        note sprintf("%5i | %s",
            $failed-at-line,
            @input-as-lines[$failed-at-line - 1],
        );

        # output position of the parser failure and what we expected (if we know).
        note $what.defined
            ?? '        ' ~ ' ' x $failed-position-in-line ~ "^ -- expected '$what'"
            !! '        ' ~ ' ' x $failed-position-in-line ~ '^ -- here';

        # output subsequent line, if present
        note sprintf("%5i | %s",
            $failed-at-line + 1,
            @input-as-lines[$failed-at-line - 0],
        ) if @input-as-lines[$failed-at-line - 0].defined;

        note '';

        exit 1;
    }
}
