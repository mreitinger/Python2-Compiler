package Python2::Type::IntType;
use base qw/ Python2::Type::Type /;
use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self) = @_;

    return bless(['int'], $self);
}

sub __call__    {
    shift @_; # $self - unused

    Python2::Type::Scalar::Num->new(int($_[0]->__tonative__));
}

sub __type__  { return $_[0][0]; }

1;
