package Python2::Stack::Frame;

use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, $values) = @_;

    return bless($values // {}, $self);
}

sub __getattr__ : lvalue {
    my ($self, $name, $gracefully) = @_;

    die Python2::Type::Exception->new("NameError", "name '$name' is not defined")
        unless defined $self->{$name} or $gracefully;

    return $self->{$name};
}

sub __setattr__ {
    my ($self, $name, $value) = @_;

    return $self->{$name} = $value;
}

sub __hasattr__ {
    my ($self, $name) = @_;

    return defined $self->{$name} ? 1 : 0;
}

sub __delattr__ {
    my ($self, $name) = @_;

    delete $self->{$name};
}

1;
