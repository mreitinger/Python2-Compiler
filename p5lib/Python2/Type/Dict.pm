package Python2::Type::Dict;

use v5.26.0;
use base qw/ Python2::Type /;

use warnings;
use strict;

use Carp qw/ confess /;
use Scalar::Util qw/ refaddr /;
use List::Util qw/ min /;
use Tie::PythonDict;

sub new {
    # initial arugments must be a array so we don't loose objects once they become hash keys
    my ($class, @initial_elements) = @_;

    tie my %elements, 'Tie::PythonDict';

    my $self = bless(\%elements, $class);

    while (@initial_elements) {
        my $key = shift @initial_elements;
        my $value = shift @initial_elements;

        $self->__setitem__($key, $value);
    }

    return $self;
}

sub __from_hash__ {
    # initial arugments must be a array so we don't loose objects once they become hash keys
    my ($class, @initial_elements) = @_;

    tie my %elements, 'Tie::PythonDict';

    my $self = bless(\%elements, $class);

    while (@initial_elements) {
        my $key = shift @initial_elements;
        my $value = shift @initial_elements;

        $self->__setitem__(Python2::Type::Scalar::String->new($key), Python2::Internals::convert_to_python_type($value));
    }

    return $self;
}

sub keys {
    my $self = shift;
    return Python2::Type::List->new(keys %$self);
}

sub iterkeys {
    my $self = shift;
    return Python2::Type::List->new(
        sort { $a->__tonative__ cmp $b->__tonative__ } CORE::keys %$self
    )->__iter__;
}

sub clear {
    my $self = shift;
    %$self = ();
}

sub values {
    my $self = shift;
    return Python2::Type::List->new(values %$self);
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

    return Python2::Type::Scalar::Num->new(scalar CORE::keys %$self);
}

sub __getitem__  : lvalue {
    my ($self, $key, $gracefully) = @_;

    die("Unhashable type: " . ref($key))
        unless $key->isa('Python2::Type::Scalar') or $key->isa('Python2::Type::Object');

    die Python2::Type::Exception->new('KeyError', 'No element with key ' . $key)
        unless $gracefully or exists $self->{$key};

    return $self->{$key};
}

sub get {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless $key->isa('Python2::Type::Scalar') or $key->isa('Python2::Type::Object');

    return exists $self->{$key} ? $self->{$key} : Python2::Type::Scalar::None->new(0);
}

sub has_key {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless $key->isa('Python2::Type::Scalar') or $key->isa('Python2::Type::Object');

    return Python2::Type::Scalar::Bool->new(exists $self->{$key});
}

sub update {
    my ($self, $dict) = @_;

    # TODO python is less strict here
    die Python2::Type::Exception->new('TypeError', 'update() expected a single dict as argument, got nothing')
        unless defined $dict;

    die Python2::Type::Exception->new('TypeError', 'Expected update() expected dict but got ' . $dict->__type__)
        unless $dict->__type__ eq 'dict';

    while (my ($key, $value) = each %$dict ) {
        $self->__setitem__($key, $value);
    }

    return Python2::Type::Scalar::None->new();
}

sub items {
    my ($self) = @_;

    my $list = Python2::Type::List->new();

    foreach my $key (sort { $a->__tonative__ cmp $b->__tonative__ } CORE::keys %$self) {
        $list->append(Python2::Type::Tuple->new($key, $self->{$key}));
    }

    return $list;
}


sub __setitem__ {
    my ($self, $key, $value) = @_;

    die("Unhashable type '" . ref($key) . "' with value '$value'")
        unless ref($key) =~ m/^Python2::Type::/;

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

sub __tonative_strings__ {
    my $self = shift;

    my $retvar = {};

    while (my ($key, $value) = each(%$self)) {
        $retvar->{$key->__print__} = ref($value) ? $value->__print__ : $value;
    }

    return $retvar;
}

sub __is_py_true__  {
    my $self = shift;
    return scalar CORE::keys %$self > 0 ? 1 : 0;
}

sub __type__ { return 'dict'; }

sub __eq__      {
    my ($self, $other) = @_;

    # if it's the same element it must match
    return Python2::Type::Scalar::Bool->new(1)
        if refaddr($self) == refaddr($other);

    # if it's not a dict just abort right here no need to compare
    return Python2::Type::Scalar::Bool->new(0)
        unless $other->__class__ eq 'Python2::Type::Dict';

    # if it's not at least the same size we don't need to compare any further
    return Python2::Type::Scalar::Bool->new(0)
        unless $self->__len__->__tonative__ == $other->__len__->__tonative__;

    # we are comparing empty lists so they are identical
    return Python2::Type::Scalar::Bool->new(1)
        if $self->__len__->__tonative__ == 0;

    # compare all elements and return false if anything doesn't match
    foreach (CORE::keys %$self) {
        return Python2::Type::Scalar::Bool->new(0)
            unless $other->has_key($_)->__tonative__;

        return Python2::Type::Scalar::Bool->new(0)
            unless $self->__getitem__($_)->__eq__($other->__getitem__($_))->__tonative__;
    }

    # all matched - return true
    return Python2::Type::Scalar::Bool->new(1);
}

sub __contains__ {
    my ($self, $key) = @_;

    return Python2::Type::Scalar::Bool->new(exists $self->{$key});
}

sub __hasattr__ {
    my ($self, $key) = @_;
    return Python2::Type::Scalar::Bool->new($self->can($key->__tonative__));
}

sub __gt__ {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new(1)
        if ($other->__type__ eq 'int');

    return Python2::Type::Scalar::Bool->new(1)
        if ($other->__type__ eq 'bool');

    return Python2::Type::Scalar::Bool->new(0)
        if ($other->__type__ eq 'list');

    return Python2::Type::Scalar::Bool->new(0)
        if ($other->__type__ eq 'tuple');

    return Python2::Type::Scalar::Bool->new(0)
        if ($other->__type__ eq 'str');

    # ref https://hg.python.org/releasing/2.7.9/file/753a8f457ddc/Objects/dictobject.c#l1792
    if ($other->__type__ eq 'dict') {
        if ($self->__len__->__tonative__ > $other->__len__->__tonative__) {
            return Python2::Type::Scalar::Bool->new(1);
        }

        if ($self->__len__->__tonative__ < $other->__len__->__tonative__) {
            return Python2::Type::Scalar::Bool->new(0);
        }

        return Python2::Type::Scalar::Bool->new(0)
            if $self->__eq__($other);
    }

    die Python2::Type::Exception->new('NotImplementedError', '__gt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __lt__ {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new(0)
        if ($other->__type__ eq 'int');

    return Python2::Type::Scalar::Bool->new(0)
        if ($other->__type__ eq 'bool');

    return Python2::Type::Scalar::Bool->new(1)
        if ($other->__type__ eq 'list');

    return Python2::Type::Scalar::Bool->new(1)
        if ($other->__type__ eq 'tuple');

    return Python2::Type::Scalar::Bool->new(1)
        if ($other->__type__ eq 'str');

    # ref https://hg.python.org/releasing/2.7.9/file/753a8f457ddc/Objects/dictobject.c#l1792
    if ($other->__type__ eq 'dict') {
        if ($self->__len__->__tonative__ < $other->__len__->__tonative__) {
            return Python2::Type::Scalar::Bool->new(1);
        }

        if ($self->__len__->__tonative__ > $other->__len__->__tonative__) {
            return Python2::Type::Scalar::Bool->new(0);
        }

        return Python2::Type::Scalar::Bool->new(0)
            if $self->__eq__($other);
    }

    die Python2::Type::Exception->new('NotImplementedError', '__lt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __call__ {
    my $self = shift;
    pop @_; # named arguments hash, unused
    my $param = shift;

    return Python2::Type::Dict->new()
        unless defined $param;

    return Python2::Type::Dict->new(
        map { $_ => $param->__getitem__($_) } $param->keys->ELEMENTS
    ) if $param->__type__ eq 'dict';

    die Python2::Type::Exception->new('TypeError', 'dict() expects a list as paramter, got ' . $param->__type__)
        unless $param->__type__ eq 'list';

    return Python2::Type::Dict->new(
        map {
            die Python2::Type::Exception->new(
                'TypeError',
                sprintf("'%s' passwd to dict() contained invalid item of type '%s', expected tuple or list", $param->__type__, $_->__type__)
            ) unless $_->__type__ =~ m/^(list|tuple)$/;

            my @elements = $_->ELEMENTS;

            $elements[0] => $elements[1];
        } $param->ELEMENTS
    );
 }

sub ELEMENTS {
    my $self = shift;
    return CORE::keys %$self;
}

1;
