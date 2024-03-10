package Python2::Type::Object::StdLib::datetime::timedelta;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use DateTime::Duration;
use DateTime::Format::Duration;
use Scalar::Util::Numeric qw(isfloat);


sub new { bless({}, shift); }

sub __call__ {
    my $self = shift;
    my $named_arguments = pop;

    my $elements = [
        [ 'days',           shift ],
        [ 'seconds',        shift ],
        [ 'microseconds',   shift ],
        [ 'milliseconds',   shift ],
        [ 'minutes',        shift ],
        [ 'hours',          shift ],
        [ 'weeks',          shift ]
    ];

    my $values = {};


    # Get positional arguments first
    foreach my $element (@$elements) {
        next unless defined $element->[1] and $element->[1];

        my $key   = $element->[0];
        my $value = $element->[1];

        die Python2::Type::Exception->new('TypeError', sprintf('Invalid type for %s positional parameter: %s', $key, $value->__type__))
            unless ref($value) eq 'Python2::Type::Scalar::Num';

        $values->{$key} = $value->__tonative__;
    }

    # Check named arguments
    foreach my $element (@$elements) {
        my $key   = $element->[0];

        next unless exists $named_arguments->{$key} and $named_arguments->{$key};

        die Python2::Type::Exception->new('TypeError', sprintf('Conflict between named and positional arguments for parameter %s.', $key))
            if exists $values->{$key};

        my $value = $named_arguments->{$key};

        die Python2::Type::Exception->new('TypeError', sprintf('Invalid type for %s named parameter: %s', $key, $value->__type__))
            unless ref($value) eq 'Python2::Type::Scalar::Num';

        $values->{$key} = $value->__tonative__;
    }

    if (exists $values->{microseconds}) {
        $values->{nanoseconds} += $values->{microseconds} * 1000;
        delete $values->{microseconds};
    }

    if (exists $values->{milliseconds}) {
        $values->{nanoseconds} += $values->{milliseconds} * 1000000;
        delete $values->{milliseconds};
    }

    return \bless({
        duration => DateTime::Duration->new(%$values)
    }, ref($self));
}

sub __print__ {
    my ($self) = @_;

    my $remaining_duration = DateTime::Format::Duration->new(pattern => '%s')->format_duration(
        $self->{duration}
    );

    # Days are always printed without leading zero
    my $d = int($remaining_duration / 86400);
    $remaining_duration -= int($d * 86_400);

    # Hours are always printed without leading zero
    my $h = $remaining_duration >=3600 ? int($remaining_duration / 3600) : "0";
    $remaining_duration -= ($h * 3600);

    # Minutes are printed as double-digits
    my $m = $remaining_duration > 60 ? sprintf('%02d', int($remaining_duration / 60)) : "00";
    $remaining_duration -= ($m * 60);

    # Seconds are printed as double-digits and with 6 trailing positions for precision if needed
    my $s = $remaining_duration =~ m/\./ ? sprintf('%02.6f', $remaining_duration) : sprintf('%02d', $remaining_duration);
    $s = "0$s" if $s =~ m/^\d\./; # workaround printf ignoring leading zero flag if precision is required

    return sprintf("%s day, %s:%s:%s", $d, $h, $m, $s)  if $d == 1;
    return sprintf("%s days, %s:%s:%s", $d, $h, $m, $s) if $d > 1;
    return sprintf("%s:%s:%s", $h, $m, $s);
}

1;