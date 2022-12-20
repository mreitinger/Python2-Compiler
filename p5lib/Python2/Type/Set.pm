package Python2::Type::Set;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

use Scalar::Util qw/ refaddr /;
use List::Util qw/ min max /;

use Python2::Internals;
use Python2::Type::Scalar::Num;

use Tie::PythonDict;

use overload
    '@{}'    => sub {
        my $self = shift;
        return [
            sort { $a->__tonative__ cmp $b->__tonative__ }
            CORE::keys %$self
        ];
    },
    fallback => 1; # Required for older Perl's - fixed with (at latest) 5.36.

sub new {
    # initial arugments must be a array so we don't loose objects once they become hash keys
    my ($class, @initial_elements) = @_;

    tie my %elements, 'Tie::PythonDict';

    my $self = bless(\%elements, $class);

    foreach(@initial_elements) {
        $self->add($_);
    }

    return $self;
}

sub __iter__ {
    die Python2::Type::Exception->new('NotImplementedError', '__iter__ for set not yet implemented');
}

sub __str__ {
    my ($self) = @_;

    return "set([" .
        join (', ',
            map {
                $_->__str__
            } sort { $a->__tonative__ cmp $b->__tonative__ } CORE::keys %$self
        ) .
    "])";
}

sub __is_py_true__  {
    my $self = shift;
    return scalar CORE::keys %$self > 0 ? 1 : 0;
}

# dummy value - we only need the keys anyway. initialize once so
# we save some overhead.
my $value = Python2::Type::Scalar::Num->new(1);
sub add {
    my ($self, $value) = @_;

    $self->{$value} = $value;
}

sub __len__ {
    my ($self) = @_;

    return \Python2::Type::Scalar::Num->new(scalar CORE::keys %$self);
}

# convert to a 'native' perl5 arrayref
sub __tonative__ {
    my $self = shift;

    return [
        map { $_->__tonative__ } @$self
    ];
}

sub ELEMENTS {
    my $self = shift;

    return @$self;
}

sub __type__ { return 'set'; }

sub __eq__      {
    my ($self, $other) = @_;

    # if it's the same element it must match
    return \Python2::Type::Scalar::Bool->new(1)
        if refaddr($self) == refaddr($other);

    # if it's not a set just abort right here no need to compare
    return \Python2::Type::Scalar::Bool->new(0)
        unless $other->__class__ eq 'Python2::Type::Set';

    # if it's not at least the same size we don't need to compare any further
    return \Python2::Type::Scalar::Bool->new(0)
        unless ${ $self->__len__ }->__tonative__ == ${ $other->__len__ }->__tonative__;

    # we are comparing empty sets so they are identical
    return \Python2::Type::Scalar::Bool->new(1)
        if ${ $self->__len__ }->__tonative__ == 0;

    my @left  = sort { $a->__tonative__ cmp $b->__tonative__ } CORE::keys %$self;
    my @right = sort { $a->__tonative__ cmp $b->__tonative__ } CORE::keys %$other;

    # compare all elements and return false if anything doesn't match
    for (my $i = 0; $i <= scalar(@left)-1; $i++) {
        return \Python2::Type::Scalar::Bool->new(0)
            unless $left[$i]->__eq__($right[$i]);
    }

    # all matched - return true
    return \Python2::Type::Scalar::Bool->new(1);
}

1;
