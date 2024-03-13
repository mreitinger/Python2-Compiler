package Python2::Type::Object::StdLib::datetime::datetime;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use POSIX;
use DateTime::Format::Strptime;
use DateTime;
use DateTime::TimeZone;

sub new {
    my $self = shift;

    return bless({}, $self);
}

sub new_from_datetime {
    my ($self, $datetime) = @_;

    die Python2::Type::Exception->new('TypeError', "new_from_datetime() expects a DateTime object")
        unless ref($datetime) eq 'DateTime';

    return bless({ datetime => $datetime}, __PACKAGE__);
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
    # TODO checks for h/m/d

    my $dt = $self->new_from_datetime(
        DateTime->new(
            year    => $year->__tonative__,
            month   => $month->__tonative__,
            day     => $day->__tonative__,
            hour    => defined $hour ? $hour->__tonative__ : 0,
            minute  => defined $minute ? $minute->__tonative__ : 0,
            second  => defined $second ? $second->__tonative__ : 0,
        )
    );

    return \$dt;
}

sub __print__ {
    # TODO: consider microseconds as python does?
    # https://stackoverflow.com/questions/33246879/how-to-get-micro-seconds-with-time-stamp-in-perl
    shift->{datetime}->strftime('%Y-%m-%d %H:%M:%S');
}

sub today { shift->now() }

sub now {
    my ($self) = @_;

    my $object = bless({
        datetime => DateTime->now()
    }, ref($self));

    return \$object;
}

sub fromtimestamp {
    my ($self, $timestamp) = @_;

    die Python2::Type::Exception->new('TypeError', 'fromtimestamp() expects an intenger as timestamp, got ' . defined $timestamp ? $timestamp->__type__ : 'nothing')
        unless defined $timestamp and $timestamp->__type__ eq 'int';

    my $object = bless({
        datetime => DateTime->from_epoch(
            epoch       => $timestamp->__tonative__,
            time_zone   => DateTime::TimeZone->new( name => 'local' )->name(),
        )
    }, ref($self));

    return \$object;
}



sub strftime {
    pop(@_); # default named arguments hash

    my ($self, $format) = @_;

    die Python2::Type::Exception->new('TypeError', 'strftime() expects a string as format, got ' . defined $format ? $format->__type__ : 'nothing')
        unless defined $format and $format->__type__ eq 'str';

    return \Python2::Type::Scalar::String->new(
        $self->{datetime}->strftime($format)
    );
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

    my $obj = $parser->parse_datetime($string);

    return \$self->new_from_datetime($obj);
}

sub __getattr__ {
    my ($self, $attr) = @_;

    return \Python2::Type::Scalar::Num->new($self->{datetime}->year) if $attr eq 'year';
    return \Python2::Type::Scalar::Num->new($self->{datetime}->month) if $attr eq 'month';
    return \Python2::Type::Scalar::Num->new($self->{datetime}->day) if $attr eq 'day';
    return \Python2::Type::Scalar::Num->new($self->{datetime}->hour) if $attr eq 'hour';
    return \Python2::Type::Scalar::Num->new($self->{datetime}->minute) if $attr eq 'minute';
    return \Python2::Type::Scalar::Num->new($self->{datetime}->second) if $attr eq 'second';

    die Python2::Type::Exception->new('AttributeError', 'datetime has no attribute ' . $attr);
}

1;
