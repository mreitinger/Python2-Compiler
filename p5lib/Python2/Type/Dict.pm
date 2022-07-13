package Python2::Type::Dict;

use v5.26.0;
use base qw/ Python2::Type /;

use warnings;
use strict;

use Scalar::Util qw/ refaddr /;
use Tie::PythonDict;

sub new {
    # initial arugments must be a array so we don't loose objects once they become hash keys
    my ($class, @initial_elements) = @_;

    tie my %elements, 'Tie::PythonDict';

    my $self = bless({
        elements => \%elements
    }, $class);

    while (my $key = shift @initial_elements) {
        my $value = shift @initial_elements;

        $self->__setitem__($key, $value);
    }

    return $self;
}

sub keys {
    return \Python2::Type::List->new(
        keys %{ shift->{elements} }
    );
}

sub values {
    my $self = shift;
    return \Python2::Type::List->new(
        values %{ $self->{elements} }
    );
}

sub __str__ {
    my ($self) = @_;

    return "{" .
        join (', ',
            map {
                $_->__str__ .
                ': ' .
                $self->{elements}->{$_}->__str__
            } sort { $a->__tonative__ cmp $b->__tonative__ } CORE::keys %{ $self->{elements} }
        ) .
    "}";
}

sub __getitem__ {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless ref($key) =~ m/^Python2::Type::(Scalar|Class::class_)/;

    return \$self->{elements}->{$key};
}

sub __setitem__ {
    my ($self, $key, $value) = @_;

    # TODO support objects as keys
    die("Unhashable type '" . ref($key) . "' with value '$value'")
        unless ref($key) =~ m/^Python2::Type::Scalar::/;

    die("PythonDict expects as Python2::Type as key gut got " . ref($key))
        unless (ref($key) =~ m/^Python2::Type::/);

    die("PythonDict expects as Python2::Type as value but got " . ref($value))
        unless (ref($value) =~ m/^Python2::Type::/);

    $self->{elements}->{$key} = $value;
}

# convert to a 'native' perl5 hashref
sub __tonative__ {
    my $self = shift;

    my $retvar = {};

    while (my ($key, $value) = each(%{ $self->{elements} })) {
        $retvar->{$key->__tonative__} = ref($value) ? $value->__tonative__ : $value;
    }

    return $retvar;
}

sub __type__ { return 'dict'; }


1;
