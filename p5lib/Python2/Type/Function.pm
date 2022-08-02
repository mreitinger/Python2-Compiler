package Python2::Type::Function;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;
use Scalar::Util qw/ refaddr /;

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

# this makes returns a true value (for "if functioname: ...") and a informative string
# as a bonus
sub __tonative__ {
    shift->__str__;
}

sub __type__ { return 'function'; }

1;
