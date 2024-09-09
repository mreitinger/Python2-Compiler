# wraps a perl hashref directly, if the dictionary gets modified so does the perl hash.
# used by convert_to_python_type to wrap perl hashrefs.
package Python2::Type::PerlHash;

use v5.26.0;
use base qw/ Python2::Type::Dict /;

use warnings;
use strict;

use Scalar::Util qw/ refaddr /;

sub new {
    my ($class, $hashref) = @_;

    die Python2::Type::Exception->new('TypeError', 'Python2::Type::PerlHash expects a HASH, got nothing')
        unless defined $hashref;

    my $self = bless([$hashref], $class);

    return $self;
}

sub keys {
    my $self = shift;

    my $keys = Python2::Type::List->new();

    $keys->append(Python2::Internals::convert_to_python_type($_)) foreach keys %{ $self->[0] };

    return $keys;
}

sub clear {
    my $self = shift;
    %{ $self->[0] } = ();
}

sub values {
    my $self = shift;

    my $values = Python2::Type::List->new();

    $values->append(Python2::Internals::convert_to_python_type($_)) foreach values %{ $self->[0] };

    return $values;
}

sub __str__ {
    my ($self) = @_;

    return "{" .
        join (', ',
            map {
                ($_ =~ m/^(\d+|\d+\.\d+)$/ ? $_ : "'$_'") .
                ': ' .
                ($self->[0]->{$_} =~ m/^(\d+|\d+\.\d+)$/ ? $self->[0]->{$_} : "'" . $self->[0]->{$_} . "'")
            } sort { $a cmp $b } CORE::keys %{ $self->[0] }
        ) .
    "}";
}

sub __len__ {
    my ($self) = @_;

    return Python2::Type::Scalar::Num->new(scalar CORE::keys %{ $self->[0] });
}

sub __getitem__ {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless ref($key) =~ m/^Python2::Type::(Scalar|Class::class_)/;

    return Python2::Internals::convert_to_python_type($self->[0]->{$key});
}

sub get {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless ref($key) =~ m/^Python2::Type::(Scalar|Class::class_)/;

    return exists $self->[0]->{$key}
        ? Python2::Internals::convert_to_python_type($self->[0]->{$key})
        : Python2::Type::Scalar::None->new(0);
}

sub has_key {
    my ($self, $key) = @_;

    die("Unhashable type: " . ref($key))
        unless ref($key) =~ m/^Python2::Type::(Scalar|Class::class_)/;

    return Python2::Type::Scalar::Bool->new(exists $self->[0]->{$key});
}

sub update {
    my ($self, $dict) = @_;

    # TODO python is less strict here
    die Python2::Type::Exception->new('TypeError', 'update() expected a single dict as argument, got nothing')
        unless defined $dict;

    die Python2::Type::Exception->new('TypeError', 'Expected update() expected dict but got ' . $dict->__type__)
        unless $dict->__type__ eq 'dict';

    while (my ($key, $value) = each %$dict ) {
        $key   = $key->__tonative__;
        $value = $value->__tonative__;
        $self->[0]->{$key} = $value;
    }

    return Python2::Type::Scalar::None->new();
}

sub items {
    my ($self) = @_;

    my $list = Python2::Type::List->new();

    while (my ($key, $value) = each %{ $self->[0] } ) {
        $list->append(Python2::Type::Tuple->new(
            Python2::Internals::convert_to_python_type($key),
            Python2::Internals::convert_to_python_type($value)
        ));
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

    $self->[0]->{$key->__tonative__} = $value->__tonative__;
}

# convert to a 'native' perl5 hashref
sub __tonative__ {
    my $self = shift;

    return $self->[0];
}

sub __is_py_true__  {
    my $self = shift;
    return scalar CORE::keys %{ $self->[0] } > 0 ? 1 : 0;
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
        unless $self->[0]->__len__->__tonative__ == $other->__len__->__tonative__;

    # we are comparing empty lists so they are identical
    return Python2::Type::Scalar::Bool->new(1)
        if $self->[0]->__len__->__tonative__ == 0;

    # compare all elements and return false if anything doesn't match
    foreach (CORE::keys %{ $self->[0]->[0] }) {
        return Python2::Type::Scalar::Bool->new(0)
            unless $other->has_key($_)->__tonative__;

        return Python2::Type::Scalar::Bool->new(0)
            unless $self->[0]->__getitem__($_)->__eq__($other->__getitem__($_))->__tonative__;
    }

    # all matched - return true
    return Python2::Type::Scalar::Bool->new(1);
}

sub __hasattr__ {
    my ($self, $key) = @_;
    return Python2::Type::Scalar::Bool->new($self->[0]->can($key->__tonative__));
}

sub __gt__ {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new(1)
        if ($other->__type__ eq 'int');

    die Python2::Type::Exception->new('NotImplementedError', '__gt__ between ' . $self->[0]->__type__ . ' and ' . $other->__type__);
}

sub __lt__ {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new(0)
        if ($other->__type__ eq 'int');

    die Python2::Type::Exception->new('NotImplementedError', '__lt__ between ' . $self->[0]->__type__ . ' and ' . $other->__type__);
}

sub __contains__ {
    my ($self, $key) = @_;

    return Python2::Type::Scalar::Bool->new(exists $self->[0]->{$key});
}

sub ELEMENTS {
    my $self = shift;

    return map
        {
            Python2::Internals::convert_to_python_type($_)
        }
        CORE::keys %{ $self->[0] };
}


1;
