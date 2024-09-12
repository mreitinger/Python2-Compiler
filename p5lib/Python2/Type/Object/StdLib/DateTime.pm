package Python2::Type::Object::StdLib::DateTime;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use DateTime;
use DateTime::TimeZone;
require POSIX;

sub new {
    my ($self) = @_;

    my $tz = POSIX::strftime("%Z", localtime());

    # Appearently DateTime::TimeZone does not know about some short names
    $tz = 'CET' if $tz eq 'CEST';
    $tz = 'Asia/Kolkata' if $tz eq 'IST';

    my $object = bless([
        Python2::Stack->new($Python2::builtins),
        {
            ts   => time,
            zone => DateTime::TimeZone->new(name => $tz),
        }
    ], $self);

    return $object;
}

sub DateTime {
    my ($self) = @_;
    return $self; # Some scripts just call DateTime() others DateTime.DateTime()
}

sub __call__ {
    pop(@_); # default named arguments hash
    my ($self, $time) = @_;
    if ($time) {
        # TODO: implement other init options as needed
        die Python2::Type::Exception->new('NotImplementedError') unless
            $time->__type__ eq 'int' || $time->__type__ eq 'float';
        my $ts = $time->__tonative__;
        # store the timestamp with -1h / 3600s (for CET) as our special python DateTime.py does
        $ts -= $self->[1]->{zone}->{last_offset};
        $self->[1]->{ts} = $ts;
    }

    return $self;
}

sub __str__ {
    return shift->strftime("%Y-%m-%d %H:%M:%S");
}

sub __tonative__ {
    my $self = shift;

    return DateTime->from_epoch(epoch => $self->[1]->{ts}, time_zone => $self->[1]->{zone});
}

sub __sub__ {
    pop(@_); # default named arguments hash
    my ($self, $d) = @_;

    # TODO
    warn $d->__type__;

    return $self;
}

sub timeTime {
    pop(@_); # default named arguments hash
    my ($self) = @_;

    return Python2::Type::Scalar::Num->new($self->[1]->{ts});

}

sub strftime {
    my ($self, $format) = @_;
    return Python2::Type::Scalar::String->new(POSIX::strftime($format, localtime($self->[1]->{ts})));
}

sub toZone {
    my ($self, $z) = @_;

    return $self;
}

sub isPast {
    # this does not behave exactly as python, in case we call isPast immediately after instance creation:
    # python says True, perl says False
    # probably bc it doesn't take microseconds into account, we'd have to use Time::HiRes
    # we don't care by now
    return Python2::Type::Scalar::Bool->new(shift->[1]->{ts} < time);
}

sub rfc822 {
    shift->strftime('%a, %e %b %Y %T GMT')
}

sub dd {
    shift->strftime('%m');
}

sub mm {
    shift->strftime('%m');
}

sub dow {
    shift->strftime('%w');
}

sub day {
    my @t = localtime(shift->[1]->{ts});
    Python2::Type::Scalar::Num->new($t[3]);
}

sub month {
    my @t = localtime(shift->[1]->{ts});
    Python2::Type::Scalar::Num->new($t[4] + 1);
}

sub year {
    my @t = localtime(shift->[1]->{ts});
    Python2::Type::Scalar::Num->new($t[5] + 1900);
}

1;
