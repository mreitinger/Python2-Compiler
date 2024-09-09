# contains the compiled code of a single python expression. used for embedding python expressions.

package Python2::Type::CodeObject;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;

use Carp qw(confess);
use Scalar::Util qw/ refaddr /;
use Python2;
use Python2::Internals;

sub new {
    my ($self, $pstack, $locals) = @_;

    return bless([Python2::Stack->new($Python2::builtins)], $self);
}

sub __call__ { ...; }
sub __name__ { ...; }

sub __str__ {
    my $self = shift;
    return sprintf('<codeobject %s at %i>', $self->__name__, refaddr($self));
}

sub __type__ { return 'codeobject'; }

sub __handle_exception__ {
    my ($self, $error) = @_;

    my $output;
    my $message;
    my $start_position;
    my $end_position;

    # some non-internal exception - just rethrow
    if (ref($error) eq 'Python2::Type::Exception') {
        $message = $error->message;

        my $trace = $error->__trace__;

        while (my $frame = $trace->next_frame) {
            next unless $frame->package =~ m/^(Python2::Type|python_class_main|DTML::Renderer)/;

            if ($frame->filename =~ m/^___position_(\d+)_(\d+)___$/) {
                $start_position = $1;
                $end_position   = $2;
                last;
            }
        }
    }
    elsif ($error =~ m/___position_(\d+)_(\d+)___/) {
        $message = $error;
        $start_position = $1;
        $end_position   = $2;
    }

    # unable to get a decent internal position - do the best we can and output a
    # perl stack trace
    unless (defined $start_position and defined $end_position) {
        die $error;
    }

    my @input_as_lines = split(/\n/, $self->__source__);

    my $failed_at_line = () = substr($self->__source__, 0, $start_position) =~ /\n/g;
    $failed_at_line++;

    my $failed_position_in_line =
        $failed_at_line > 1
            ?
                (
                    $start_position  # total position (in charaters) where the execution failed

                    # ignore all characters from preceeding lines
                    - length(join("\n", @input_as_lines[0 .. $failed_at_line - 2]))

                    # ignore last \n
                    -1
                )
            :
                $start_position;

    # output line with syntax error
    $output .= sprintf("%5i | %s\n",
        $failed_at_line,
        $input_as_lines[$failed_at_line - 1],
    );

    $output .= '        ' . ' ' x $failed_position_in_line;
    $output .= '^' x ($end_position - $start_position) . " - $message\n";

    # some error that contained a valid position but is not a Python 2 exception.
    # most of those are implementation bugs ("Not an ARRAY reference at ___position_1228_1253___ line 999.")
    confess $output unless ref($error) eq 'Python2::Type::Exception';

    die $output;
}

package Python2::Type::CodeObject::Anonymous;

use base qw/Python2::Type::CodeObject/;

sub new {
    my ($self, $source, $callee) = @_;

    return bless([Python2::Stack->new($Python2::builtins), $source, $callee], $self);
}

sub __source__ {
    $_[0][1]
}

sub __call__ {
    my ($self, $locals, $parent) = @_;
    $_[0][2]->($self, $locals, $parent)
}

1;
