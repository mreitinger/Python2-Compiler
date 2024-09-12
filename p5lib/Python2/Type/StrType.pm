package Python2::Type::StrType;
use base qw/ Python2::Type::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2::Internals;

sub new {
    my ($self, $type) = @_;

    return bless([$type], $self);
}

sub __call__    {
    my $self = shift;
    pop @_; # named arguments hash, unused

    return Python2::Type::Scalar::String->new('') unless @_;

    # TODO - this attempts to convert way more than python
    return $_[0]->__type__ eq 'str'
        # __str__ for string returns "'str'" - workaround
        # so we get matching output to python2
        ?  Python2::Type::Scalar::String->new($_[0]->__tonative__)
        :  Python2::Type::Scalar::String->new($_[0]->__str__);
}

sub __type__  { return $_[0][0]; }

1;
