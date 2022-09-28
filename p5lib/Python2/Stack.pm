package Python2::Stack;

use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self) = shift;
    return bless([@_], $self);
}

sub __getattr__ {
    my ($self, $attribute_name) = @_;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    return \$self->[1]->{$attribute_name->__tonative__};
}

sub __hasattr__ {
    my ($self, $attribute_name) = @_;

    die Python2::Type::Exception->new('TypeError', '__hasattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    return \Python2::Type::Scalar::Bool->new(exists $self->[1]->{$attribute_name->__tonative__});
}

sub __parent__ { return shift->[0]; }

1;