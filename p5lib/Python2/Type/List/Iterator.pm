package Python2::Type::List::Iterator;
use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, $list) = @_;

    return bless([0, $list], $self);
}

sub __next__ {
    my $self = shift;

    # TODO implement StopIteration exception
    return $self->[1]->__getitem__( Python2::Type::Scalar::Num->new($self->[0]++) );
}

1;