package Python2::Type::TupleType;
use base qw/ Python2::Type::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2::Internals;

sub new {
    my ($self) = @_;

    return bless(['tuple'], $self);
}

sub __call__    {
    shift @_; # $self - unused
    pop   @_; # default named arguments hash - unused

    my $value = $_[0];

    return Python2::Type::Tuple->new() unless defined $value;

    # TODO python allows more like passing a dict results in a list of the keys
    die Python2::Type::Exception->new('TypeError', 'tuple() expects some iterable, got ' . $value->__type__)
        unless $value->can('__iter__');

    return Python2::Type::Tuple->new( $value->ELEMENTS );
}

sub __type__  { return $_[0][0]; }

1;
