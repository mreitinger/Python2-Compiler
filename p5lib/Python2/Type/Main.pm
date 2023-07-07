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
use Python2::Internals;
use Carp qw/ confess /;

sub new {
    return bless([Python2::Stack->new($Python2::builtins)], shift);
}

# execute our main block with error handler
sub __run__ {
    my ($self, $args) = @_;

    my $retval = eval { $self->__block__($args); };

    return $retval unless $@;

    $self->__handle_exception__($@)
        if (ref($@) eq 'Python2::Type::Exception');

    # some other exception - rethrow
    die;
}

# execute our main block with error handler
sub __run_function__ {
    my ($self, $name, $argument_list) = @_;

    confess("Python2::NamedArgumentsHash missing in call to __run_function__")
        unless ref($argument_list->[-1]) eq 'Python2::NamedArgumentsHash';

    my $named_arguments = pop @$argument_list;

    # convert named arguments to python types
    foreach my $argument (keys %$named_arguments) {
        $named_arguments->{$argument} = Python2::Internals::convert_to_python_type( $named_arguments->{$argument} );
    }


    # convert positionals to python types
    foreach my $argument (@$argument_list) {
        $argument = ${ Python2::Internals::convert_to_python_type( $argument ) };
    }

    # exec the main block so we get all function definitions
    eval { $self->__block__(); };
    $self->__handle_exception__($@) if $@;

    # get our function from the stack and disable recursion
    my $coderef = Python2::Internals::getvar($self->[0], 0, $name);

    my $retval = eval {
        die("Function $name not found") unless defined $$coderef;
        $$coderef->__call__(@$argument_list, $named_arguments)
    };

    $self->__handle_exception__($@) if $@;

    return $retval;
}

sub __getattr__ { use Carp; Carp::confess; }

sub __handle_exception__ {
    my ($self, $error) = @_;

    my $output;
    my $message;
    my $start_position;
    my $end_position;

    # some non-internal exception - just rethrow
    # TOD actual line numbers and original filename
    if (ref($error) eq 'Python2::Type::Exception') {
        $message = $error->message;

        my $trace = $error->__trace__;

        while (my $frame = $trace->next_frame) {
            next unless $frame->package =~ m/^(Python2::Type|python_class_main)/;

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

    $output .= "Execution failed at line $failed_at_line ($start_position, $end_position)\n\n";

    # output preceeding line, if present
    $output .= sprintf("%5i | %s\n",
        $failed_at_line - 1,
        $input_as_lines[$failed_at_line - 2],
    ) if (($failed_at_line-1 > 0) and (defined $input_as_lines[$failed_at_line - 1]));

    # output line with syntax error
    $output .= sprintf("%5i | %s\n",
        $failed_at_line,
        $input_as_lines[$failed_at_line - 1],
    );

    $output .= '        ' . ' ' x $failed_position_in_line;
    $output .= '^' x ($end_position - $start_position) . " - $message\n";

    # output subsequent line, if present
    $output .= sprintf("%5i | %s\n",
        $failed_at_line + 1,
        $input_as_lines[$failed_at_line - 0],
    ) if defined $input_as_lines[$failed_at_line - 0];

    $output .= "\n";

    # some error that contained a valid position but is not a Python 2 exception.
    # most of those are implementaiton bugs ("Not an ARRAY reference at ___position_1228_1253___ line 999.")
    confess $output unless ref($error) eq 'Python2::Type::Exception';

    if (exists $ENV{ENABLE_PYTHON2_INTERNAL_STACK_TRACE}) {
     $output .= "Internal stack trace:\n";

        while (my $frame = $error->__trace__->next_frame) {
            $output .= sprintf(" - %s(%s)\n", $frame->subroutine, join(', ', map { substr( defined $_ ? $_ : 'undef', 0, 20 ) } $frame->args));
        }
    }

    die $output;
}

sub __parent__ { return shift->[0]; }

sub __type__ { return 'pyobject'; }

1;
