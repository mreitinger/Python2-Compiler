package Python2::Type::Dict;
use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, @initial_elements) = @_;

    return bless({
        elements    => { @initial_elements },
        stack       => { # make it look like a normal object. it'll inhert from a base class soon
                         # enough.
            funcs => {
                keys => sub {
                    return Python2::Type::List->new(keys %{ shift->[0]->{elements} })
                },
                values => sub {
                    return Python2::Type::List->new(values %{ shift->[0]->{elements} })
                },
            },
        },
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

sub element {
    my ($self, $key) = @_;

    return $self->{elements}->{$key};
}

1;
