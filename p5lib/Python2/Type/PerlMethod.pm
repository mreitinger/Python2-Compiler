# This class is used to wrap methods from 'external' perl objects
#
# Used to wrap functions that get returned by something overriding
# the local/parent namespace and returning coderefs

package Python2::Type::PerlMethod;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2::Internals;

use Carp qw/ confess /;
use Scalar::Util qw/ refaddr /;

sub new {
    my ($self, $coderef, $object, $method_name) = @_;

    die Python2::Type::Exception->new('TypeError', "PerlMethod expects a coderef but got " . (ref($coderef) ? ref($coderef) : 'scalar'))
        unless ref($coderef) eq 'CODE';

    return bless([
        $coderef, $object, $method_name
    ], $self);
}

sub __call__ {
    my ($self, @argument_list) = @_;

    # last argument is the hashref with named arguments
    my $named_arguments = pop(@argument_list);

    confess("Python2::NamedArgumentsHash missing when calling perl5 method " . $self->[2] . " on " . ref($self->[1]))
        unless ref($named_arguments) eq 'Python2::NamedArgumentsHash';

    # convert all 'Python' objects to native representations
    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__;
    }

    foreach my $argument (keys %$named_arguments) {
        $named_arguments->{$argument} = $named_arguments->{$argument}->__tonative__;
    }

    my @retval;

    eval {
        # This matches the calling conventions for Inline::Python so Perl code written to work with
        # Inline::Python in mind can keep working as-is.
        @retval = scalar keys %$named_arguments
            ? $self->[0]->($self->[1], [@argument_list], $named_arguments)
            : $self->[0]->($self->[1], @argument_list);
    };

    # If execution of the method returned errors wrap it into a Python2 style Exception
    # so the error location is correctly shown.
    die Python2::Type::Exception->new('Exception', $@) if $@;

    if (scalar(@retval) > 1) {
        return Python2::Internals::convert_to_python_type([@retval]);
    }
    else {
        return Python2::Internals::convert_to_python_type($retval[0]);
    }
}

# Workaround for broken DTML templates:
#   <dtml-var "this_be_a_function_call.method()">)
#   should be
#   <dtml-var "this_be_a_function_call().method()">)
sub __getattr__ { shift->__call__(bless({}, 'Python2::NamedArgumentsHash')); }

sub __str__ {
    my $self = shift;
    return sprintf("<perlmethod '%s' of object '%s' at %i>", $self->[2], ref($self->[1]), refaddr($self));
}

sub __tonative__ { die 'Trying to use ' . $_[0]->__str__ . ' as value. Forgot ()?' }

sub __type__ { return 'perlmethod'; }

1;
