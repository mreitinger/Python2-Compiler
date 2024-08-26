use v6.e.PREVIEW;

use DTML::Grammar;
use DTML::Actions;
use DTML::Backend::Perl5;
use Python2::ParseFail;
use Python2::CompilationError;

unit class DTML::Compiler;

method compile(Str $input, Str :$embedded) {
    my $backend = DTML::Backend::Perl5.new(:compiler(self));
    my $ast = DTML::Grammar.new.parse($input, :actions(DTML::Actions.new)).ast;
    CATCH {
        # generic parser error
        when X::Syntax::Confused {
            self.handle-parse-fail(:$input, :pos($_.pos));
        }

        # our custom exceptions
        when Python2::ParseFail {
            self.handle-parse-fail(:$input, :pos($_.pos), :what($_.what));
        }
    }
    note $ast;
    my $perl = $backend.e($ast, :$embedded);
    note $perl;
    $perl
}

method handle-parse-fail(Str :$input, Int :$pos is copy, Str :$what?) {
    my Str $message;

    $pos++; # TODO maybe ranges would work better (highlight from-to if appropriate)

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

    $message ~= "Parsing failed at line $failed-at-line:\n\n";

    # output preceeding line, if present
    $message ~= sprintf("%5i | %s\n",
        $failed-at-line - 1,
        @input-as-lines[$failed-at-line - 2],
    ) if @input-as-lines[$failed-at-line - 2].defined;

    # output line with syntax error
    $message ~= sprintf("%5i | %s\n",
        $failed-at-line,
        @input-as-lines[$failed-at-line - 1],
    );

    # output position of the parser failure and what we expected (if we know).
    $message ~= $what.defined
        ?? '       ' ~ ' ' x $failed-position-in-line ~ "^ -- $what\n"
        !! '       ' ~ ' ' x $failed-position-in-line ~ "^ -- here\n";

    # output subsequent line, if present
    $message ~= sprintf("%5i | %s\n",
        $failed-at-line + 1,
        @input-as-lines[$failed-at-line - 0],
    ) if @input-as-lines[$failed-at-line - 0].defined;

    $message ~= "\n";

    Python2::CompilationError.new(:error($message)).throw();
}
