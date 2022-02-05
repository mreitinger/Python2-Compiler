package Python2::Type::List;
use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, @initial_elements) = @_;

    return bless({
        elements => [ @initial_elements ],
    }, $self);
}

sub print {
    my ($self) = @_;
    say '[' . join(', ', map { $_ =~ m/^\d+$/ ? $_ : "'$_'" } @{ $self->{elements} }) . ']';
}

sub elements { shift->{elements} }

sub element {
    my ($self, $key) = @_;

    return \$self->{elements}->[$key];
}

sub set {
    my ($self, $key, $value) = @_;

    $self->{elements}->[$key] = $value;
}

sub __len__ {
    my ($self) = @_;

    return scalar@{ $self->{elements} };
}

sub __setitem__ {
    my ($self, $key, $value) = @_;

    $self->{elements}->[$key] = $value;
}

1;
