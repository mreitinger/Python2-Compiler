package Python2::Type::Object::StdLib::datetime;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Python2::Type::Object::StdLib::datetime::datetime;

sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins, {
            datetime => Python2::Type::Object::StdLib::datetime::datetime->new()
        }],
    }, $self);

    return $object;
}

sub datetime {
    my ($self, @args) = @_;

    $self->{stack}->[1]->{datetime}->__call__(@args);
}

1;
