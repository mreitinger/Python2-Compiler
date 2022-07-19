# base class for our 'main' object

package Python2::Type::Main;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;

use Scalar::Util qw/ refaddr /;
use Data::Dumper;
use Ref::Util::XS qw/ is_arrayref is_hashref is_coderef /;
use Python2;

sub new {
    return bless({ stack => [$builtins] }, shift);
}

# execute our main block with error handler
sub __run__ {
    my ($self, $args) = @_;

    my $retval = eval { $self->__block__($args); };

    return $retval unless $@;

    $self->__handle_python_exception__($@)
        if (ref($@) eq 'Python2::Type::Exception');

    # some other exception - rethrow
    die;
}

sub __handle_python_exception__ {
    my ($self, $error) = @_;

    my $output;

    my $message        = $error->message;

    my $start_position;
    my $end_position;
    while (my $frame = $error->__trace__->next_frame) {
        next unless $frame->package =~ m/^(Python2::Type|python_class_main)/;

        if ($frame->filename =~ m/^___position_(\d+)_(\d+)___$/) {
            $start_position = $1;
            $end_position   = $2;
        }
    }

    # unable to get a decent internal position - do the best we can and output a
    # perl stack trace
    unless ($start_position and $end_position) {
        die $error->__trace__->as_string;
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

    $output .= "Execution failed at line $failed_at_line ($start_position, $end_position)\n\n";

    # output preceeding line, if present
    $output .= sprintf("%5i | %s\n",
        $failed_at_line - 1,
        $input_as_lines[$failed_at_line - 2],
    ) if defined $input_as_lines[$failed_at_line - 2];

    # output line with syntax error
    $output .= sprintf("%5i | %s\n",
        $failed_at_line,
        $input_as_lines[$failed_at_line - 1],
    );

    $output .= '        ' . ' ' x $failed_position_in_line;
    $output .= '^' x ($end_position - $start_position - 1) . " - $message\n";

    # output subsequent line, if present
    $output .= sprintf("%5i | %s\n",
        $failed_at_line + 1,
        $input_as_lines[$failed_at_line - 0],
    ) if defined $input_as_lines[$failed_at_line - 0];

    $output .= "\n";

    $output .= "Internal stack trace:\n";

    while (my $frame = $error->__trace__->next_frame) {
        $output .= sprintf(" - %s(%s)\n", $frame->subroutine, join(', ', map { substr( $_, 0, 20 ) } $frame->args));
    }

    die $output;
}

sub __type__ { return 'pyobject'; }

1;
