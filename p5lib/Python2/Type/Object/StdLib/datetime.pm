package Python2::Type::Object::StdLib::datetime;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Python2::Type::Object::StdLib::datetime::datetime;
use Python2::Type::Object::StdLib::datetime::timedelta;

sub new {
    my ($self) = @_;

    my $object = bless({
        classes => {
            datetime    => "Python2::Type::Object::StdLib::datetime::datetime",
            timedelta   => "Python2::Type::Object::StdLib::datetime::timedelta",
        }
    }, $self);

    return $object;
}

sub __getattr__ {
    my ($self, $attribute_name) = @_;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    my $object = $self->{classes}->{$attribute_name}->new();
    return $object;
}

sub __hasattr__ {
    my ($self, $attribute_name) = @_;

    die Python2::Type::Exception->new('TypeError', '__hasattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    return Python2::Type::Scalar::Bool->new(
        exists $self->{classes}->{$attribute_name}
    );
}

1;
