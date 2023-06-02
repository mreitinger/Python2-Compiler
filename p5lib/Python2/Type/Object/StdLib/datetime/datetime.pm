package Python2::Type::Object::StdLib::datetime::datetime;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

require POSIX;
require DateTime::Format::Strptime;

sub new {
    my ($self, $year, $month, $day, $hour, $minute, $second) = @_;

    my $object = bless([
        Python2::Stack->new($Python2::builtins),
        {
            year   => Python2::Type::Scalar::Num->new($year // -1),
            month  => Python2::Type::Scalar::Num->new($month // -1),
            day    => Python2::Type::Scalar::Num->new($day // -1),
            hour =>  Python2::Type::Scalar::Num->new($hour // 0),
            minute =>  Python2::Type::Scalar::Num->new($minute // 0),
            second => Python2::Type::Scalar::Num->new($second // 0)
        }
    ], $self);

    return $object;
}

sub __posix__ {
    my $o = shift->[1];
    # POSIX: sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1
    # TODO: implement remaining elements?
    $o->{second}->__tonative__,
    $o->{minute}->__tonative__,
    $o->{hour}->__tonative__,
    $o->{day}->__tonative__,
    $o->{month}->__tonative__,
    $o->{year}->__tonative__;
}

sub __call__ {
    pop(@_); # default named arguments hash
    my ($self, $year, $month, $day, $hour, $minute, $second) = @_;

    die Python2::Type::Exception->new('TypeError', "Required argument 'year' (pos 1) not found")
        unless ($year && $year->__type__ eq 'int');
    die Python2::Type::Exception->new('TypeError', "Required argument 'month' (pos 2) not found")
        unless ($month && $month->__type__ eq 'int');
    die Python2::Type::Exception->new('TypeError', "Required argument 'day' (pos 3) not found")
        unless ($day && $day->__type__ eq 'int');

    $$year -= 1900;
    $$month -= 1;

    $self->[1]->{year} = $year;
    $self->[1]->{month} = $month;
    $self->[1]->{day} = $day;
    $self->[1]->{hour} = $hour if $hour;
    $self->[1]->{minute} = $minute if $minute;
    $self->[1]->{second} = $second if $second;

    return \$self;
}

sub __print__ {
    # TODO: consider microseconds as python does?
    # https://stackoverflow.com/questions/33246879/how-to-get-micro-seconds-with-time-stamp-in-perl
    POSIX::strftime("%Y-%m-%d %H:%M:%S", shift->__posix__);
}

sub now {
    pop(@_); # default named arguments hash

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

    return \Python2::Type::Object::StdLib::datetime::datetime->new(
        Python2::Type::Scalar::Num->new($year),
        Python2::Type::Scalar::Num->new($mon),
        Python2::Type::Scalar::Num->new($mday),
        Python2::Type::Scalar::Num->new($hour),
        Python2::Type::Scalar::Num->new($min),
        Python2::Type::Scalar::Num->new($sec)
    )
}

sub strftime {
    pop(@_); # default named arguments hash

    my ($self, $format) = @_;

    return \Python2::Type::Scalar::String->new(POSIX::strftime($format, $self->__posix__));
}

sub strptime {
    pop(@_); # default named arguments hash
    my ($self, $string, $format) = @_;

    my $parser = DateTime::Format::Strptime->new(
        pattern => $format,
        on_error => sub {
            my ($object, $message) = @_;

            die Python2::Type::Exception->new('Exception', $message);
        },
    );
    my $obj = $parser->parse_datetime($string)->{local_c};

    return \Python2::Type::Object::StdLib::datetime::datetime->new(
        Python2::Type::Scalar::Num->new($obj->{year} - 1900),
        Python2::Type::Scalar::Num->new($obj->{month} - 1),
        Python2::Type::Scalar::Num->new($obj->{day}),
        Python2::Type::Scalar::Num->new($obj->{hour}),
        Python2::Type::Scalar::Num->new($obj->{minute}),
        Python2::Type::Scalar::Num->new($obj->{second})
    )
}

1;
