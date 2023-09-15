# wraps a perl arrayref directly, if the list gets modified so does the perl array.
# used by convert_to_python_type to wrap perl arrayrefs.

package Python2::Type::PerlArray;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

use Scalar::Util qw/ refaddr /;
use List::Util qw/ min max /;
use Scalar::Util qw/ refaddr /;

use Python2::Internals;


sub new {
    my ($class, $arrayref) = @_;

    die Python2::Type::Exception->new('TypeError', 'Python2::Type::PerlArray expects a ARRAY, got nothing')
        unless defined $arrayref;

    my $self = bless([$arrayref], $class);

    return $self;
}

sub __str__ {
    my ($self) = @_;

    return
        '[' .
            join(', ', map {
                # TODO inplement a print-like-python method for perl data structures
                # TODO this is currently a very high overhead but only used for tests
                ${ Python2::Internals::convert_to_python_type($_) }->__str__
            } @{ $self->[0] }) .
        ']';
}

sub __iadd__ {
    my $self = shift;

    push(@{ $self->[0] }, shift->__tonative__);
}

sub append   {
    my $self = shift;
    push(@{ $self->[0] }, shift->__tonative__);
    return \Python2::Type::Scalar::None->new();
}

sub __getitem__ {
    my ($self, $key) = @_;

    return Python2::Internals::convert_to_python_type(
        $self->[0]->[$key->__tonative__]
    );
}

sub __setitem__ {
    my ($self, $key, $value) = @_;

    $self->[0]->[$key->__tonative__] = $value->__tonative__;
}

sub __tonative__ {
    my $self = shift;

    return $self->[0];
}

sub __type__ { return 'list'; }

sub __hasattr__ {
    my ($self, $key) = @_;
    return \Python2::Type::Scalar::Bool->new($self->[0]->can($key->__tonative__));
}

sub __len__ {
    my ($self) = @_;

    return \Python2::Type::Scalar::Num->new(scalar @{ $self->[0] });
}

sub __lt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(0) if ref($other) eq 'Python2::Type::Scalar::Num';
    return \Python2::Type::Scalar::Bool->new(1) if ref($other) eq 'Python2::Type::Scalar::String';
    return \Python2::Type::Scalar::Bool->new(0) if $other->__type__ eq 'list';
    return \Python2::Type::Scalar::Bool->new(0) if $other->__type__ eq 'dict';
    die Python2::Type::Exception->new('NotImplementedError', '__lt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __gt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(1) if ref($other) eq 'Python2::Type::Scalar::Num';
    return \Python2::Type::Scalar::Bool->new(0) if ref($other) eq 'Python2::Type::Scalar::String';
    return \Python2::Type::Scalar::Bool->new(0) if $other->__type__ eq 'list';
    return \Python2::Type::Scalar::Bool->new(1) if $other->__type__ eq 'dict';
    die Python2::Type::Exception->new('NotImplementedError', '__gt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __is_py_true__ {
    my $self = shift;
    return scalar @{ $self->[0] };
}

sub extend {
    pop @_;
    my ($self, $value) = @_;

    die Python2::Type::Exception->new('TypeError', 'extend() expects a list, got nothing')
        unless defined $value;

    die Python2::Type::Exception->new('TypeError', 'extend() expects a list, got ' . $value->__type__)
        unless $value->__type__ eq 'list';

    foreach($value->ELEMENTS) {
        push(@{ $self->[0] }, $_->__tonative__);
    }

    return \Python2::Type::Scalar::None->new();
}

sub reverse {
    my $self = shift;

    @{ $self->[0] } = CORE::reverse @{ $self->[0] };

    return \Python2::Type::Scalar::None->new();
}

sub __contains__ {
    my ($self, $other) = @_;

    foreach my $item (@{ $self->[0] }) {
        $item = ${ Python2::Internals::convert_to_python_type($item) };
        return \Python2::Type::Scalar::Bool->new(1)
            if ${ $item->__eq__($other) }->__tonative__;
    }

    return \Python2::Type::Scalar::Bool->new(0);
}

sub remove {
    my ($self, $other) = @_;

    die Python2::Type::Exception->new('TypeError', 'remove() takes exactly one argument, got nothing')
        unless defined $other;

    for my $i (0 .. @{ $self->[0] }-1 ) {
        my $item = ${ Python2::Internals::convert_to_python_type($self->[0]->[$i]) };
        warn "$self - $item";

        if (${ $item->__eq__($other) }->__tonative__) {
            splice(@{ $self->[0] }, $i, 1);
            return \Python2::Type::Scalar::None->new();
        }
    }

    die Python2::Type::Exception->new('ValueError', 'list.remove() - item not in list');
}

sub ELEMENTS {
    my ($self) = @_;

    return map { ${ Python2::Internals::convert_to_python_type($_) } } @{ $self->[0] };
}

sub __eq__      {
    my ($self, $other) = @_;

    # if it's the same element it must match
    return \Python2::Type::Scalar::Bool->new(1)
        if $self->REFADDR eq $other->REFADDR;

    # if it's not a list just abort right here no need to compare
    return \Python2::Type::Scalar::Bool->new(0)
        unless $other->__type__ eq 'list';

    # if it's not at least the same size we don't need to compare any further
    return \Python2::Type::Scalar::Bool->new(0)
        unless ${ $self->__len__ }->__tonative__ == ${ $other->__len__ }->__tonative__;

    # we are comparing empty lists so they are identical
    return \Python2::Type::Scalar::Bool->new(1)
        if ${ $self->__len__ }->__tonative__ == 0;

    # compare all elements and return false if anything doesn't match
    foreach (0 .. ${ $self->__len__ }->__tonative__ -1) {
        return \Python2::Type::Scalar::Bool->new(0)
            unless  ${
                ${ $self->__getitem__(Python2::Type::Scalar::Num->new($_) ) }
                    ->__eq__(${ $other->__getitem__(Python2::Type::Scalar::Num->new($_)) });
            }->__tonative__;
    }

    # all matched - return true
    return \Python2::Type::Scalar::Bool->new(1);
}

sub __getslice__ {
    my ($self, $key, $target) = @_;

    my $perl_array_length = scalar @{ $self->[0] };

    $key     = $key->__tonative__;
    $target  = $target->__tonative__;

    if ($target == '-1') {
        $target = $perl_array_length;
    }

    # if the target is longer than the list cap it
    if ($target > $perl_array_length ) {
        $target = $perl_array_length;
    }

    return \Python2::Type::List->new(
        map { ${ Python2::Internals::convert_to_python_type($_) } }
        @{ $self->[0] } [$key .. $target - 1]
    );
}

sub sort {
    my $self = shift;
    my $named_arguments = pop;

    my $key     = exists $named_arguments->{key} ? ${ $named_arguments->{key} } : undef;
    my $reverse = exists $named_arguments->{reverse} ? ${ $named_arguments->{reverse} } : undef;

    die Python2::Type::Exception->new('TypeError', 'Value passed to sorted must be bool or int, got ' . $reverse->__type__)
        if defined $reverse and $reverse->__type__ !~ m/^(int|bool)$/;

    die Python2::Type::Exception->new('TypeError', 'key passed to sorted is not callable (does not support __call__)')
        if defined $key and not $key->can('__call__');

    # both bool and int work here
    $reverse = defined $reverse ? $reverse->__tonative__ : 0;

    my @result = $key
        ?   sort {
                ${ $key->__call__(${ Python2::Internals::convert_to_python_type($a) }, bless({}, 'Python2::NamedArgumentsHash')) }->__tonative__
                cmp
                ${ $key->__call__(${ Python2::Internals::convert_to_python_type($b) }, bless({}, 'Python2::NamedArgumentsHash')) }->__tonative__
            } $self->ELEMENTS

        :   sort {
                $a cmp $b
            } @{ $self->[0] }
        ;

    @{ $self->[0] } = $reverse
        ? reverse @result
        : @result;

    return \Python2::Type::Scalar::None->new();
}

sub REFADDR {
    my ($self) = @_;
    return refaddr($self->[0]);
}

1;
