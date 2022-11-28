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

    # we don't support named arguments but still expect the empty hash - just here to catch bugs
    die Python2::Type::Exception->new('NotImplementedError', "expected named arguments hash when calling perl5 method " . $self->[2] . " on " . ref($self->{object}))
        unless ref($named_arguments) eq 'HASH';

    # convert all 'Python' objects to native representations
    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__;
    }

    foreach my $argument (keys %$named_arguments) {
        $named_arguments->{$argument} = ${$named_arguments->{$argument}}->__tonative__;
    }

    # This matches the calling conventions for Inline::Python so Perl code written to work with
    # Inline::Python can keep working as-is.

    my @retval;

    eval {
        @retval = scalar keys %$named_arguments
            ? $self->[0]->($self->[1], [@argument_list], $named_arguments)
            : $self->[0]->($self->[1], @argument_list);
    };

    if ($@) {
        die Python2::Type::Exception->new('Exception', $@);
    }

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
