# wraps a perl hashref directly, if the dictionary gets modified so does the perl hash.
# used by convert_to_python_type to wrap perl hashrefs.
package Python2::Type::PerlHash;

use v5.26.0;
use base qw/ Python2::Type::Dict /;

use warnings;
use strict;

sub new {
    my ($class, $hashref) = @_;

    die Python2::Type::Exception->new('TypeError', 'Python2::Type::PerlHash expects a HASH, got nothing')
        unless defined $hashref;

    my $self = bless($hashref, $class);

    return $self;
}

sub keys {
    my $self = shift;

    my $keys = Python2::Type::List->new();

    $keys->append(${ Python2::Internals::convert_to_python_type($_) }) foreach keys %$$self;

    return \$keys;
}

sub clear {
    my $self = shift;
    %$self = ();
}

sub values {
    my $self = shift;

    my $values = Python2::Type::List->new();

    $values->append(${ Python2::Internals::convert_to_python_type($_) }) foreach values %$$self;

    return \$values;
}

sub __str__ {
    my ($self) = @_;

    return "{" .
        join (', ',
            map {
                ($_ =~ m/^(\d+|\d+\.\d+)$/ ? $_ : "'$_'") .
                ': ' .
                ($$self->{$_} =~ m/^(\d+|\d+\.\d+)$/ ? $$self->{$_} : "'" . $$self->{$_} . "'")
            } sort { $a cmp $b } CORE::keys %$$self
        ) .
    "}";
}

sub __len__ {
    my ($self) = @_;

    return \Python2::Type::Scalar::Num->new(scalar CORE::keys %$$self);
}

sub __getitem__ {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless ref($key) =~ m/^Python2::Type::(Scalar|Class::class_)/;

    return Python2::Internals::convert_to_python_type($$self->{$key});
}

sub get {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless ref($key) =~ m/^Python2::Type::(Scalar|Class::class_)/;

    return exists $self->{$key}
        ? Python2::Internals::convert_to_python_type($$self->{$key})
        : \Python2::Type::Scalar::None->new(0);
}

sub has_key {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless ref($key) =~ m/^Python2::Type::(Scalar|Class::class_)/;

    return \Python2::Type::Scalar::Bool->new(exists $$self->{$key});
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

    return \Python2::Type::Scalar::None->new();
}

sub items {
    my ($self) = @_;

    my $list = Python2::Type::List->new();

    while (my ($key, $value) = each %$$self ) {
        $list->append(Python2::Type::Tuple->new(
            ${ Python2::Internals::convert_to_python_type($key) },
            ${ Python2::Internals::convert_to_python_type($value) }
        ));
    }

    return \$list;
}


sub __setitem__ {
    my ($self, $key, $value) = @_;

    die("Unhashable type '" . ref($key) . "' with value '$value'")
        unless ref($key) =~ m/^Python2::Type::/;

    die("PythonDict expects as Python2::Type as key gut got " . ref($key))
        unless (ref($key) =~ m/^Python2::Type::/);

    die("PythonDict expects as Python2::Type as value but got " . ref($value))
        unless (ref($value) =~ m/^Python2::Type::/);

    $$self->{$key->__tonative__} = $value->__tonative__;
}

# convert to a 'native' perl5 hashref
sub __tonative__ {
    my $self = shift;

    return $$self;
}

sub __is_py_true__  {
    my $self = shift;
    return scalar CORE::keys %$$self > 0 ? 1 : 0;
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

sub __hasattr__ {
    my ($self, $key) = @_;
    return \Python2::Type::Scalar::Bool->new($self->can($key->__tonative__));
}

sub __gt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(1)
        if ($other->__type__ eq 'int');

    die Python2::Type::Exception->new('NotImplementedError', '__gt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __lt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(0)
        if ($other->__type__ eq 'int');

    die Python2::Type::Exception->new('NotImplementedError', '__lt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

1;
