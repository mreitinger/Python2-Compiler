# we might have to split this into Int/Float/Complex

package Python2::Type::Scalar::Num;
use v5.26.0;
use base qw/ Python2::Type::Scalar /;
use warnings;
use strict;

sub __str__ {return shift->{value}; }

sub __type__ { shift->{value} =~ m/^\d+$/ ? 'int' : 'float'; }

sub __ne__ {
    my ($self, $pstack, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ ne $other->__tonative__);
}

sub __gt__ {
    my ($self, $pstack, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ > $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    ...;
}

sub __lt__ {
    my ($self, $pstack, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ < $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    ...;
}

sub __ge__ {
    my ($self, $pstack, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ >= $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    ...;
}

sub __le__ {
    my ($self, $pstack, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ <= $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    ...;
}

sub __or__ {
    my ($self, $pstack, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) | int($other->__tonative__));
}

sub __and__ {
    my ($self, $pstack, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) & int($other->__tonative__));
}

sub __xor__ {
    my ($self, $pstack, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) ^ int($other->__tonative__));
}

sub __lshift__ {
    my ($self, $pstack, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) << int($other->__tonative__));
}

sub __rshift__ {
    my ($self, $pstack, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) >> int($other->__tonative__));
}

1;
