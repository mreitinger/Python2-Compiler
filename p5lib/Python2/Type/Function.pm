package Python2::Type::Function;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2::Stack;
use Python2::Internals;
use Scalar::Util qw/ refaddr /;


sub new {
    my ($self, $pstack) = @_;

    return bless({
        stack => Python2::Stack->new($pstack)
    }, $self);
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

        my @py_args;
        foreach my $argument (@argument_list) {
            push @py_args, Python2::Internals::convert_to_python_type($argument);
        }

        my $retval = $self->__call__(@py_args);
        return $retval->__tonative__;
    };

    return $retval;
}

sub __type__ { return 'function'; }

1;
