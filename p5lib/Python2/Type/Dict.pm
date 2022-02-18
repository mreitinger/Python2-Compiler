package Python2::Type::Dict;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

sub new {
    my ($self, @initial_elements) = @_;

    return bless({
        stack => [ undef, { elements => { @initial_elements } } ],
    }, $self);
}

sub keys {
    my $self = shift;
    return \Python2::Type::List->new(keys %{ $self->{stack}->[1]->{elements} });
}

sub values {
    my $self = shift;
    return \Python2::Type::List->new(values  %{ $self->{stack}->[1]->{elements} })
}

sub print {
    my ($self) = @_;

    my $var = $self->{stack}->[1]->{elements};

    say "{" .
        join (', ',
            map {
                ($_ =~ m/^\d+$/ ? $_ : "'$_'") .  # TODO add a quote-like-python function
                ': ' .
                ($var->{$_} =~ m/^\d+$/ ? $var->{$_} : "'$var->{$_}'")
            } sort CORE::keys %$var
        ) .
    "}";
}

sub element {
    my ($self, $key) = @_;

    return \$self->{stack}->[1]->{elements}->{$key};
}

sub set {
    my ($self, $key, $value) = @_;

    $self->{stack}->[0]->{elements}->{$key} = $value;
}

# convert to a 'native' perl5 hashref
sub __tonative__ {
    my $self = shift;

    my $retvar = {};

    while (my ($key, $value) = each(%{ $self->{stack}->[1]->{elements} })) {
        $retvar->{$key} = ref($value) ? $value->__tonative__ : $value;
    }

    return $retvar;
}


1;
