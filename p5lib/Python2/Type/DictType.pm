package Python2::Type::DictType;
use base qw/ Python2::Type::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2::Internals;

sub new {
    my ($self) = @_;

    return bless(['dict'], $self);
}

sub __call__    {
    my $self = shift;
    pop @_; # named arguments hash, unused
    my $param = shift;

    return Python2::Type::Dict->new()
        unless defined $param;

    return Python2::Type::Dict->new(
        map { $_ => $param->__getitem__($_) } $param->keys->ELEMENTS
    ) if $param->__type__ eq 'dict';

    die Python2::Type::Exception->new('TypeError', 'dict() expects a list as paramter, got ' . $param->__type__)
        unless $param->__type__ eq 'list';

    return Python2::Type::Dict->new(
        map {
            die Python2::Type::Exception->new(
                'TypeError',
                sprintf("'%s' passwd to dict() contained invalid item of type '%s', expected tuple or list", $param->__type__, $_->__type__)
            ) unless $_->__type__ =~ m/^(list|tuple)$/;

            my @elements = $_->ELEMENTS;

            $elements[0] => $elements[1];
        } $param->ELEMENTS
    );
}

sub __type__  { return $_[0][0]; }

1;
