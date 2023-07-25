use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;
use Python2::Optimizer;
use Python2::ParseFail;
use Python2::CompilationError;

class Python2::Compiler {
    has Bool $.optimize = True;
    has Bool $.dumpast  = False;

    has $.backend = Python2::Backend::Perl5.new(
        :compiler(self),
    );

    has $.parser                = Python2::Grammar::Complete.new();
    has $.expression-parser     = Python2::Grammar::ExpressionsOnly.new();
    has $.actions               = Python2::Actions::Complete.new();
    has $.expression-actions    = Python2::Actions::ExpressionsOnly.new();
    has $.optimizer             = Python2::Optimizer.new();

    method compile (
            Str $input,             # Python 2 source code

            Str :$embedded,         # class name to use as 'main' class.
                                    # used when embedding the code in some other environment where the caller
                                    # needs to know the main class name
                                    # if this is set the call to main->block() is not included in the output
                                    # and is left for the caller to execute so parameters can be passed.

            Bool :$module = False,  # determines if we are compiling a module or standalone script.
                                    # if set to True this will not allow a main block and embedded must be set
                                    # so our caller can specify the module name

            :@import-names          # optional - provide a list of names to import from the to-be-compiled module
                                    # this will be passed to the backend method compiling the root node which will
                                    # filter the nodes
    ) {
        die("Module compilation requested but no embedded named passed, check embedded parameter")
            if $module and not $embedded;

        my $ast = $!parser.parse($input, actions => $!actions);

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

        my $root = $ast.made.clone;

        $!optimizer.t($root) if $.optimize;

        if ($.dumpast)  {
            note $root;
            exit 0;
        }

        return $!backend.e($root, :$module, :$embedded, :@import-names);
    }

    method compile-expression (Str $input!, Str :$embedded!) {
        my $ast = $.expression-parser.parse($input, actions => $!expression-actions);

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

        my $root = $ast.made.clone;

        $!optimizer.t($root) if $.optimize;

        if ($.dumpast)  {
            note $root;
            exit 0;
        }

        return $!backend.e($root, :expression(True), :$embedded);
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
}
