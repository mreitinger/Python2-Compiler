package Python2::Type::Scalar::String;
use v5.26.0;
use base qw/ Python2::Type::Scalar /;
use warnings;
use strict;

sub __str__  { return "'" . shift->{value} . "'"; }
sub __type__ { 'str'; }

sub split {
    pop(@_); # default named arguments hash
    my ($self, $separator, $maxsplit) = @_;

    my $joiner = $separator; # original separator - used to join in case we use maxsplit below

    if ($separator) {
        die("Expected a scalar as seperator")
            unless $separator->__type__ eq 'str';

        $separator = $separator->__tonative__;
        $separator = "\Q$separator\E";
    }
    else {
        $separator = '\s+';
    }

    my @result = split($separator, $self->{value});

    if ($maxsplit) {
        $maxsplit       = $maxsplit->__tonative__;
        my $result_size = scalar(@result);

        # clamp to result size
        $maxsplit = $result_size if $maxsplit > $result_size;

        my $ret = \Python2::Type::List->new(
            map { Python2::Type::Scalar::String->new($_) } @result[0 .. $maxsplit-1],
            (
                ($result_size-$maxsplit > 0)
                    ? join($joiner->__tonative__, @result[$maxsplit .. $result_size-1])
                    : ()
            )
        );

        return $ret;
    }

    return \Python2::Type::List->new(map { Python2::Type::Scalar::String->new($_) } @result);
}

sub join {
    my ($self, $iterable) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("join() expects a iterable but got '%s'", $iterable->__type__))
        unless ($iterable->__type__ eq 'list');

    return \Python2::Type::Scalar::String->new(join($self->__tonative__, map {
        die Python2::Type::Exception->new('TypeError', sprintf("expected string but found '%s' in iterable", $_->__type__))
            unless $_->__type__ eq 'str';

        $_->__tonative__;
    } @$iterable ));
}

sub __gt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ gt $other->__tonative__)
        if ($other->__type__ eq 'str');

    ...;
}

sub __lt__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ lt $other->__tonative__)
        if ($other->__type__ eq 'str');

    ...;
}

sub __ge__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ ge $other->__tonative__)
        if ($other->__type__ eq 'str');

    ...;
}

sub __le__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new($self->__tonative__ le $other->__tonative__)
        if ($other->__type__ eq 'str');

    ...;
}

1;
