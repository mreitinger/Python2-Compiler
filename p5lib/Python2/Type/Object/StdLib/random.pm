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
    my ($self, $pstack, $seed) = @_;
    $rseed = $seed;
    srand($rseed);
    return \Python2::Type::Scalar::None->new();
}

sub choice {
    pop(@_); # default named arguments hash
    my ($self, $pstack, $sequence) = @_;

    die Python2::Type::Exception->("IndexError", "sequence with length 0 given")
        unless scalar @{ $sequence } > 0;

    die Python2::Type::Exception->(
        "TypeError", $sequence->__type__ . ".choice() expecting list, got " . $sequence->__type__)
        unless ref($sequence) =~ m/^Python2::Type::List/;

    srand($rseed) if ($rseed);

    my @list = @{ $sequence->__tonative__ };

    my $rand_elem =  rand(scalar @list);

    my $selected_elem = $list[$rand_elem];

    return Python2::Internals::convert_to_python_type($selected_elem);
}

sub shuffle {
    pop(@_); # default named arguments hash
    my ($self, $pstack, $sequence, $random) = @_;

    # this is not 100% correct as python allows other types under certain circumstances
    # but good enough for our application
    die Python2::Type::Exception->(
        "TypeError", $sequence->__type__ . ".choice() expecting list, got " . $sequence->__type__)
        unless ref($sequence) =~ m/^Python2::Type::List/;

    srand($rseed) if ($rseed);

    @$sequence = List::Util::shuffle @$sequence;

    return \Python2::Type::Scalar::None->new();
}

1;
