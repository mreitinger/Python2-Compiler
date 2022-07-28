package Python2::Type::List;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

use Scalar::Util qw/ refaddr /;
use List::Util qw/ min max /;

sub new {
    my ($self, @initial_elements) = @_;

    return bless([@initial_elements], $self);
}

sub __str__ {
    my $self = shift;

    return '[' . join(', ', map { $_->__str__ } @{ $self }) . ']';
}

sub __iadd__ { my $self = shift; push(@$self, shift); }
sub append   { shift->__iadd__(shift); }

sub __getitem__ {
    my ($self, $key) = @_;

    return \$self->[$key->__tonative__];
}

sub __iter__ { \Python2::Type::List::Iterator->new(shift); }

sub __getslice__ {
    my ($self, $key, $target) = @_;

    $key     = $key->__tonative__;
    $target  = $target->__tonative__;

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
    my ($self, $key, $value) = @_;

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

sub __eq__      {
    my ($self, $other) = @_;

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
                ${ $self->__getitem__( Python2::Type::Scalar::Num->new($_) ) }
                    ->__eq__(${ $other->__getitem__(Python2::Type::Scalar::Num->new($_)) });
            }->__tonative__;
    }

    # all matched - return true
    return \Python2::Type::Scalar::Bool->new(1);
}

sub __contains__ {
    my ($self, $other) = @_;

    foreach my $item (@$self) {
        return \Python2::Type::Scalar::Bool->new(1)
            if ${ $item->__eq__($other) }->__tonative__;
    }

    return \Python2::Type::Scalar::Bool->new(0);
}

1;
