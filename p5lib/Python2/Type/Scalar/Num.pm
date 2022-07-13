# we might have to split this into Int/Float/Complex

package Python2::Type::Scalar::Num;
use v5.26.0;
use base qw/ Python2::Type::Scalar /;
use warnings;
use strict;

sub __str__ {return shift->{value}; }

sub __type__ { shift->{value} =~ m/^\d+$/ ? 'int' : 'float'; }

sub __ne__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ ne $other->__tonative__);
}

sub __gt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ > $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    ...;
}

sub __lt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ < $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    ...;
}

sub __ge__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ >= $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    ...;
}

sub __le__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ <= $other->__tonative__)
        if ($other->__class__ eq 'Python2::Type::Scalar::Num');

    ...;
}

1;
