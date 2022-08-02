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

    my $self = bless(\%elements, $class);

    while (my $key = shift @initial_elements) {
        my $value = shift @initial_elements;

        $self->__setitem__($key, $value);
    }

    return $self;
}

sub keys {
    my $self = shift;
    return \Python2::Type::List->new(keys %$self);
}

sub clear {
    my $self = shift;
    %$self = ();
}

sub values {
    my $self = shift;
    return \Python2::Type::List->new(values %$self);
}

sub __str__ {
    my ($self) = @_;

    return "{" .
        join (', ',
            map {
                $_->__str__ .
                ': ' .
                $self->{$_}->__str__
            } sort { $a->__tonative__ cmp $b->__tonative__ } CORE::keys %$self
        ) .
    "}";
}

sub __len__ {
    my ($self) = @_;

    return \Python2::Type::Scalar::Num->new(scalar CORE::keys %$self);
}

sub __getitem__ {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless ref($key) =~ m/^Python2::Type::(Scalar|Class::class_)/;

    return \$self->{$key};
}

sub has_key {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless ref($key) =~ m/^Python2::Type::(Scalar|Class::class_)/;

    return \Python2::Type::Scalar::Bool->new(exists $self->{$key});
}


sub __setitem__ {
    my ($self, $key, $value) = @_;

    die("Unhashable type '" . ref($key) . "' with value '$value'")
        unless ref($key) =~ m/^Python2::Type::Scalar::/;

    die("PythonDict expects as Python2::Type as key gut got " . ref($key))
        unless (ref($key) =~ m/^Python2::Type::/);

    die("PythonDict expects as Python2::Type as value but got " . ref($value))
        unless (ref($value) =~ m/^Python2::Type::/);

    $self->{$key} = $value;
}

# convert to a 'native' perl5 hashref
sub __tonative__ {
    my $self = shift;

    my $retvar = {};

    while (my ($key, $value) = each(%$self)) {
        $retvar->{$key->__tonative__} = ref($value) ? $value->__tonative__ : $value;
    }

    return $retvar;
}

sub __type__ { return 'dict'; }

sub __eq__      {
    my ($self, $other) = @_;

    # if it's the same element it must match
    return \Python2::Type::Scalar::Bool->new(1)
        if refaddr($self) == refaddr($other);

    # if it's not a dict just abort right here no need to compare
    return \Python2::Type::Scalar::Bool->new(0)
        unless $other->__class__ eq 'Python2::Type::Dict';

    # if it's not at least the same size we don't need to compare any further
    return \Python2::Type::Scalar::Bool->new(0)
        unless ${ $self->__len__ }->__tonative__ == ${ $other->__len__ }->__tonative__;

    # we are comparing empty lists so they are identical
    return \Python2::Type::Scalar::Bool->new(1)
        if ${ $self->__len__ }->__tonative__ == 0;

    # compare all elements and return false if anything doesn't match
    foreach (CORE::keys %$self) {
        return \Python2::Type::Scalar::Bool->new(0)
            unless ${ $other->has_key($_) }->__tonative__;

        return \Python2::Type::Scalar::Bool->new(0)
            unless ${
                ${ $self->__getitem__($_) }->__eq__(${ $other->__getitem__($_) });
            }->__tonative__;
    }

    # all matched - return true
    return \Python2::Type::Scalar::Bool->new(1);
}

1;
