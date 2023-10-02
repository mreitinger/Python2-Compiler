# we might have to split this into Int/Float/Complex

package Python2::Type::Scalar::Num;
use v5.26.0;
use base qw/ Python2::Type::Scalar /;
use warnings;
use strict;

sub __str__ {return $_[0]->$*; }

sub __type__ { $_[0]->$* =~ m/^\-?\d+$/ ? 'int' : 'float'; }

sub __is_py_true__  { $_[0]->$* != 0 ? 1 : 0; }

sub __eq__ {
    my ($self, $other) = @_;

    die Python2::Type::Exception->new('Exception', 'Bool->__eq__() called without $other')
        unless defined $other;

    return \Python2::Type::Scalar::Bool->new(0)
        if $other->__type__ eq 'none';

    return \Python2::Type::Scalar::Bool->new(
        ($self->__tonative__ // 0) == ($other->__tonative__ // 0)
    ) if $other->__type__ eq 'bool';

    return \Python2::Type::Scalar::Bool->new(0)
        if $other->__type__ ne $self->__type__;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ == $other->__tonative__);
}

sub __ne__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(1)
        if $other->__type__ eq 'none';

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ ne $other->__tonative__);
}

sub __gt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(1)
        if $other->__type__ eq 'none';

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ > $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    return \Python2::Type::Scalar::Bool->new(0)
        if ref($other) eq 'Python2::Type::Scalar::String';

    die Python2::Type::Exception->new('NotImplementedError', '__gt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __lt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(0)
        if $other->__type__ eq 'none';

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ < $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    die Python2::Type::Exception->new('NotImplementedError', '__lt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __ge__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(1)
        if $other->__type__ eq 'none';

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ >= $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    return \Python2::Type::Scalar::Bool->new(0)
        if ref($other) eq 'Python2::Type::Scalar::String';

    die Python2::Type::Exception->new('NotImplementedError', '__ge__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __le__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(0)
        if $other->__type__ eq 'none';

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ <= $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    die Python2::Type::Exception->new('NotImplementedError', '__le__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __or__ {
    my ($self, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) | int($other->__tonative__));
}

sub __and__ {
    my ($self, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) & int($other->__tonative__));
}

sub __xor__ {
    my ($self, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) ^ int($other->__tonative__));
}

sub __lshift__ {
    my ($self, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) << int($other->__tonative__));
}

sub __rshift__ {
    my ($self, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("bitwise or expects int, got %s and %s", $self->__type__, $other->__type__))
        unless (($self->__type__ eq 'int') and ($other->__type__ eq 'int'));

    return \Python2::Type::Scalar::Num->new(int($self->__tonative__) >> int($other->__tonative__));
}

sub __call__ {
    my $self = shift;

    # This is a very, very ugly hack for compatibility with ancient Zope/DTML templates.
    # Some mechanism allowed values to be accessed as a Function Call: <dtml-var "my_number()">
    return \$self;
}




1;
