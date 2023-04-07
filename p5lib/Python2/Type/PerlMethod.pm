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

sub new {
    my ($self, $coderef, $object, $method_name) = @_;

    return bless([
        $coderef, $object, $method_name
    ], $self);
}

sub __call__ {
    my ($self, @argument_list) = @_;

    # last argument is the hashref with named arguments
    my $named_arguments = pop(@argument_list);

    confess("Python2::NamedArgumentsHash missing when calling perl5 method " . $self->[2] . " on " . ref($self->{object}))
        unless ref($named_arguments) eq 'Python2::NamedArgumentsHash';

    die Python2::Type::Exception->new('NotImplementedError', "named arguments not supported when calling perl5 method " . $self->[2] . " on " . ref($self->{object}))
        if scalar keys %$named_arguments;

    # convert all 'Python' objects to native representations
    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__;
    }

    my @retval;

    eval {
        @retval = $self->[0]->($self->[1], @argument_list);
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

sub __str__ {
    my $self = shift;
    return sprintf("<perlmethod '%s' of object '%s' at %i>", $self->[2], ref($self->[1]), refaddr($self));
}

sub __tonative__ { ...; }

sub __type__ { return 'perlmethod'; }

1;