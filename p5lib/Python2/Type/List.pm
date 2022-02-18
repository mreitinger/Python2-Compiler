package Python2::Type::List;
use v5.26.0;
use base qw/ Python2::Type /;
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

# convert to a 'native' perl5 arrayref
sub __tonative__ {
    return [
        map { ref($_) ? $_->__tonative__ : $_ } @{ shift->elements }
    ];
}

1;
