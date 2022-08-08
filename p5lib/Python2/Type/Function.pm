package Python2::Type::Function;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2::Internals;

sub new {
    my ($self) = @_;

    my $object = bless([], $self);

    return $object;
}

sub __call__ { ...; }
sub __name__ { ...; }

sub __str__ {
    my $self = shift;
    return sprintf('<function %s at %i>', $self->__name__, refaddr($self));
}

# create a wrapper for the python function (also lambdas). this converts arguments passed from
# a pure-perl caller to our internal types and returns a pure-perl representation of the result.
sub __tonative__ {
    my $self = shift;

    my $retval = sub {
        my @argument_list = @_;

        foreach my $argument (@argument_list) {
            $argument = ${ Python2::Internals::convert_to_python_type($argument) };
        }

        my $retval = $self->__call__(@argument_list);
        return ${ $retval }->__tonative__;
    };

    return $retval;
}

sub __type__ { return 'function'; }

1;
