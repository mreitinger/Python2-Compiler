package Python2::Stack::Frame;

use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, $values) = @_;

    return bless($values // {}, $self);
}

sub __getattr__ {
    my ($self, $name) = @_;

    return \$self->{$name};
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