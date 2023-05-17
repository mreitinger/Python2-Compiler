package Python2::Type::Method;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

use Scalar::Util qw/ refaddr /;

sub new {
    my ($self, $pstack, $object) = @_;

    die("Python2::Type::Method created without object")
        unless ref($object);

    return bless({
        stack  => Python2::Stack->new($pstack),
        object => $object,
    }, $self);
}

sub __str__ {
    my $self = shift;
    return sprintf('<method %s of %s at %i>', $self->__name__, ref($self->{object}), refaddr($self));
}

# create a wrapper for the python method. this converts arguments passed from a pure-perl caller
# to our internal types and returns a pure-perl representation of the result.
sub __tonative__ {
    my $self = shift;

    my $retval = sub {
        my @argument_list = ($self, @_);

        foreach my $argument (@argument_list) {
            $argument = ${ Python2::Internals::convert_to_python_type($argument) };
        }

        my $retval = $self->__call__(@argument_list);
        return ${ $retval }->__tonative__;
    };

    return $retval;
}

sub __type__ { return 'method'; }

1;
