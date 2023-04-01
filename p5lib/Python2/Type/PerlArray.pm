# wraps a perl arrayref directly, if the list gets modified so does the perl array.
# used by convert_to_python_type to wrap perl arrayrefs.

package Python2::Type::PerlArray;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

use Scalar::Util qw/ refaddr /;
use List::Util qw/ min max /;

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

    push(@$self, shift->__tonative__);
}

sub append   {
    my $self = shift;
    push(@$self, shift->__tonative__);
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

    return \Python2::Type::Scalar::Num->new(scalar @$self);
}

sub __is_py_true__ {
    my $self = shift;
    return scalar @$self;
}

sub extend {
    pop @_;
    my ($self, $value) = @_;

    die Python2::Type::Exception->new('TypeError', 'extend() expects a list, got nothing')
        unless defined $value;

    die Python2::Type::Exception->new('TypeError', 'extend() expects a list, got ' . $value->__type__)
        unless $value->__type__ eq 'list';

    foreach(@$value) {
        $self->[0]->append($_);
    }

    return \Python2::Type::Scalar::None->new();
}

sub __contains__ {
    my ($self, $other) = @_;

    foreach my $item (@$self) {
        $item = ${ Python2::Internals::convert_to_python_type($item) };
        return \Python2::Type::Scalar::Bool->new(1)
            if ${ $item->__eq__($other) }->__tonative__;
    }

    return \Python2::Type::Scalar::Bool->new(0);
}

sub ELEMENTS {
    my ($self) = @_;

    return map { ${ Python2::Internals::convert_to_python_type($_) } } @{ $self->[0] };
}

sub __eq__      {
    my ($self, $other) = @_;

    # if it's the same element it must match
    return \Python2::Type::Scalar::Bool->new(1)
        if $self->[0]->REFADDR eq $other->REFADDR;

    # if it's not a list just abort right here no need to compare
    return \Python2::Type::Scalar::Bool->new(0)
        unless $other->__type__ eq 'Python2::Type::PerlArray';

    # if it's not at least the same size we don't need to compare any further
    return \Python2::Type::Scalar::Bool->new(0)
        unless ${ $self->[0]->__len__ }->__tonative__ == ${ $other->__len__ }->__tonative__;

    # we are comparing empty lists so they are identical
    return \Python2::Type::Scalar::Bool->new(1)
        if ${ $self->[0]->__len__ }->__tonative__ == 0;

    # compare all elements and return false if anything doesn't match
    foreach (0 .. ${ $self->[0]->__len__ }->__tonative__ -1) {
        return \Python2::Type::Scalar::Bool->new(0)
            unless  ${
                ${ $self->[0]->__getitem__(Python2::Type::Scalar::Num->new($_) ) }
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


1;
