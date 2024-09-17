package Python2::Type::Object::StdLib::random;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use List::Util;
use Python2::Internals qw/ convert_to_python_type /;

my $rseed;

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$Python2::builtins] }, $self);

    return $object;
}

sub seed {
    pop(@_); # default named arguments hash
    my ($self, $seed) = @_;
    $rseed = $seed;
    srand($rseed);
    return Python2::Type::Scalar::None->new();
}

sub random {
    my ($self) = @_;

    return Python2::Type::Scalar::Num->new(rand(1));
}

sub randint {
    pop(@_); # named arguments hash, unused

    my ($self, $lower, $upper) = @_;

    die Python2::Type::Exception->new("TypeError", "random.randint(lower, upper) expecting int as lower bound, got " . (defined $lower ? $lower->__type__ : 'nothing'))
        unless defined $lower and $lower->__type__ eq 'int';

    die Python2::Type::Exception->new("TypeError", "random.randint(lower, upper) expecting int as upper bound, got " . (defined $upper ? $upper->__type__ : 'nothing'))
        unless defined $upper and $upper->__type__ eq 'int';

    return Python2::Type::Scalar::Num->new(
        int($lower->__tonative__ + rand($upper->__tonative__ - $lower->__tonative__))
    );
}

sub randrange {
    pop(@_); # named arguments hash, unused

    my ($self, $lower, $upper, $step) = @_;

    my ($start, $end, $x);

    if (defined $upper) {
        my $start = $lower->__tonative__;
        my $end = $upper->__tonative__;
        my $x = defined($step) ? $step->__tonative__ : 1;
    }
    else {
        $start = 0;
        $end = $lower->__tonative__;
        $x = 1;
    }
    my $range = int(($end - $start) / $x);

    return Python2::Type::Scalar::Num->new(
        $start + int(rand($range)) * $x
    );
}

sub sample {
    pop(@_); # default named arguments hash
    my ($self, $sequence, $count) = @_;

    die Python2::Type::Exception->new(
        "TypeError", "random.sample() expecting int as sample size, got " . $sequence->__type__)
        unless $count->__type__ eq 'int';

    die Python2::Type::Exception->new(
        "TypeError", "random.sample() expecting list, got " . $sequence->__type__)
        unless $sequence->__type__ eq 'list';

    die Python2::Type::Exception->new(
        "ValueError", sprintf("random.sample() sample size (%i) larger than population (%i)", $count->__tonative__, scalar $sequence->ELEMENTS))
        if $count->__tonative__ > scalar $sequence->ELEMENTS;

    die Python2::Type::Exception->new(
        "ValueError", "random.sample() invalid sample size")
        if $count->__tonative__ < 0;

    return Python2::Type::List->new(
        List::Util::sample($count->__tonative__, $sequence->ELEMENTS)
    );
}



sub choice {
    pop(@_); # default named arguments hash
    my ($self, $sequence) = @_;

    die Python2::Type::Exception->new("IndexError", "sequence with length 0 given")
        unless scalar @{ $sequence } > 0;

    die Python2::Type::Exception->new(
        "TypeError", "random.choice() expecting list, got " . $sequence->__type__)
        unless $sequence->__type__ eq 'list';

    srand($rseed) if ($rseed);

    my @list = @{ $sequence->__tonative__ };

    my $rand_elem =  rand(scalar @list);

    my $selected_elem = $list[$rand_elem];

    return Python2::Internals::convert_to_python_type($selected_elem);
}

sub shuffle {
    pop(@_); # default named arguments hash
    my ($self, $sequence, $random) = @_;

    # this is not 100% correct as python allows other types under certain circumstances
    # but good enough for our application
    die Python2::Type::Exception->new(
        "TypeError", "random.shuffle() expecting list, got " . $sequence->__type__)
        unless $sequence->__type__ eq 'list';

    srand($rseed) if ($rseed);

    @$sequence = List::Util::shuffle @$sequence;

    return Python2::Type::Scalar::None->new();
}

1;
