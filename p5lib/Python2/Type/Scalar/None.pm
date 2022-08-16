package Python2::Type::Scalar::None;
use v5.26.0;
use base qw/ Python2::Type::Scalar /;
use warnings;
use strict;

sub new {
    my ($self, $value) = @_;

    return bless([], $self);
}

sub __str__         { 'None'; }
sub __tonative__    { undef; }
sub __type__        { 'none'; }
sub __print__       { 'None'; }

sub __is__          {
    my ($self, $pstack, $other) = @_;

    # special case: None is None
    return \Python2::Type::Scalar::Bool->new(1)
        if $self->__class__ eq $other->__class__;

    # everything else is false when compared to None
    return \Python2::Type::Scalar::Bool->new(0);
}

sub __eq__ {
    my ($self, $pstack, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(1)
        if ($other->__type__ eq 'none');

    return \Python2::Type::Scalar::Bool->new(0)
        if ($other->__type__ eq 'none');
}

1;
