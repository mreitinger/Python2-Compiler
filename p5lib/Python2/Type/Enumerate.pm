package Python2::Type::Enumerate;
use v5.26.0;
use warnings;
use strict;

use Python2::Type::Tuple;
use Python2::Type::Scalar::Num;

sub new {
    my ($self, $iterable) = @_;

    # TODO validate iterable

    return bless([0, $iterable], $self);
}

sub next {
    my $self = shift;

    return \Python2::Type::Tuple->new(
        Python2::Type::Scalar::Num->new($self->[0]),
        ${ $self->[1]->__getitem__( Python2::Type::Scalar::Num->new($self->[0]++) ) }
    );
}

1;