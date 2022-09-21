package Python2::Type::List;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

use Scalar::Util qw/ refaddr /;
use List::Util qw/ min max /;

use Python2::Internals;

sub new {
    my ($self, @initial_elements) = @_;

    return bless([@initial_elements], $self);
}

sub __is_py_true__  {
    my $self = shift;
    return scalar @$self > 0 ? 1 : 0;
}

sub __str__ {
    my $self = shift;

    return '[' . join(', ', map { Python2::Internals::unescape( $_->__str__ ) } @{ $self }) . ']';
}

sub __iadd__ {
    my $self = shift;
    shift; # unused parent stack
    push(@$self, shift);
}

sub append   {
    my $self = shift;
    shift; # unused parent stack
    push(@$self, shift);
}

sub __getitem__ {
    my ($self, $pstack, $key) = @_;

    return \$self->[$key->__tonative__];
}

sub __iter__ { \Python2::Type::List::Iterator->new(shift); }

sub __getslice__ {
    my ($self, $pstack, $key, $target) = @_;

    $key     = $key->__tonative__;
    $target  = $target->__tonative__;

    if ($target == '-1') {
        $target = ${ $self->__len__ }->__tonative__;
    }

    # if the target is longer than the list cap it
    if ($target > ${ $self->__len__ }->__tonative__ ) {
        $target = ${ $self->__len__}->__tonative__;
    }

    return \Python2::Type::List->new( @$self[$key .. $target - 1] );
}

sub __len__ {
    my ($self) = @_;

    return \Python2::Type::Scalar::Num->new(scalar @$self);
}

sub __setitem__ {
    my ($self, $pstack, $key, $value) = @_;

    $self->[$key->__tonative__] = $value;
}

# convert to a 'native' perl5 arrayref
sub __tonative__ {
    my $self = shift;

    return [
        map { $_->__tonative__ } @$self
    ];
}

sub __type__ { return 'list'; }

sub __hasattr__ {
    my ($self, $pstack, $key) = @_;
    return \Python2::Type::Scalar::Bool->new($self->can($key->__tonative__));
}

sub __eq__      {
    my ($self, $pstack, $other) = @_;

    # if it's the same element it must match
    return \Python2::Type::Scalar::Bool->new(1)
        if refaddr($self) == refaddr($other);

    # if it's not a list just abort right here no need to compare
    return \Python2::Type::Scalar::Bool->new(0)
        unless $other->__class__ eq 'Python2::Type::List';

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
                ${ $self->__getitem__(undef, Python2::Type::Scalar::Num->new($_) ) }
                    ->__eq__(undef, ${ $other->__getitem__(undef, Python2::Type::Scalar::Num->new($_)) });
            }->__tonative__;
    }

    # all matched - return true
    return \Python2::Type::Scalar::Bool->new(1);
}

sub __contains__ {
    my ($self, $pstack, $other) = @_;

    foreach my $item (@$self) {
        return \Python2::Type::Scalar::Bool->new(1)
            if ${ $item->__eq__(undef, $other) }->__tonative__;
    }

    return \Python2::Type::Scalar::Bool->new(0);
}

sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused
    pop   @_; # default named arguments hash - unused

    my $value = $_[0] // Python2::Type::List->new();

    # TODO python allows more like passing a dict results in a list of the keys
    die Python2::Type::Exception->new('TypeError', 'list() expects some iterable, got ' . $value->__type__)
        unless $value->can('__iter__');

    return \Python2::Type::List->new(@{ $value });
};

1;
