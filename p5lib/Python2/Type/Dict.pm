package Python2::Type::Dict;
use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, @initial_elements) = @_;

    return bless({
        elements => { @initial_elements },
    }, $self);
}

sub print {
    my ($self) = @_;

    my $var = $self->{elements};

    say "{" .
        join (', ',
            map {
                ($_ =~ m/^\d+$/ ? $_ : "'$_'") .  # TODO add a quote-like-python function
                ': ' .
                ($var->{$_} =~ m/^\d+$/ ? $var->{$_} : "'$var->{$_}'")
            } sort keys %$var
        ) .
    "}";
}

sub elements { ... }

1;
