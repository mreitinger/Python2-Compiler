package Python2::Type::XRange;
use v5.26.0;
use warnings;
use strict;
use POSIX;

sub new {
    my ($self, $start, $stop, $step) = @_;

    if (defined $start or defined $stop or defined $step) {
        die("XRange->new(): expected int for start") unless ($start =~ m/^\-?\d+$/);
        die("XRange->new(): expected int for stop")  unless ($stop =~ m/^\-?\d+$/);
        die("XRange->new(): expected int for step")  unless ($step =~ m/^\-?\d+$/);

        my $length;
        # ascending range
        if (($step > 0) and ($start < $stop)) {
            $length = ceil(($stop - $start) / $step);
        }

        # descending range
        elsif (($step < 0) and ($stop < $start)) {
            $length = floor(($start - $stop) / $step) * -1;
        }

        # everything else is 'invalid'
        else {
            $length = 0;
        }

        return bless([$start, $length, $step], $self);
    }
    else {
        return bless([], $self);
    }
}

sub __type__ { 'xrange' }
sub __name__ { 'xrange' }

sub __iter__ { die Python2::Type::Exception->new('NotImplementedError', '__iter__() for xrange'); }

sub __call__ {
    shift @_; # $self - unused
    pop @_; # named arguments hash

    die Python2::Type::Exception->new('TypeError', 'xrange() expected at least one parameter, got 0')
        unless @_;

    my ($arg_1, $arg_2, $arg_3) = @_;

    die Python2::Type::Exception->new('TypeError', 'xrange() integer expected as first argument, got ' . (defined $arg_1 ? $arg_1->__type__ : 'nothing'))
        unless defined $arg_1 and $arg_1->__type__ eq 'int';

    die Python2::Type::Exception->new('TypeError', 'xrange() integer expected as second argument, got ' . $arg_2->__type__)
        if defined $arg_2 and $arg_2->__type__ ne 'int';

    die Python2::Type::Exception->new('TypeError', 'xrange() integer expected as third argument, got ' . $arg_3->__type__)
        if defined $arg_3 and $arg_3->__type__ ne 'int';

    my $start = defined $arg_2 ? $arg_1 : 0;
    my $stop  = defined $arg_2 ? $arg_2 : $arg_1;
    my $step  = defined $arg_3 ? $arg_3 : 1;

    return \Python2::Type::XRange->new($start, $stop, $step);
};

sub __print__ {
    my $self = shift;

    # see Python-2.7/Objects/rangeobject.c
    return $self->[0] == 0
        ? sprintf('xrange(%i)',     $self->[0] + $self->[1] * $self->[2])
        : $self->[2] == 1
          ? sprintf('xrange(%i, %i)', $self->[0], $self->[0] + $self->[1] * $self->[2])
          : sprintf('xrange(%i, %i, %s)', $self->[0], $self->[0] + $self->[1] * $self->[2], $self->[2]);
}

sub ELEMENTS {
    my ($self) = @_;

    # length == 0, just shortcut it here
    return () if $self->[1] == 0;

    my @elements;

    # iterate over our length
    if ($self->[2] > 0) {
        foreach my $position (0 .. $self->[1] - 1) {
            push(@elements, Python2::Type::Scalar::Num->new($self->[0] + $position * $self->[2]));
        }
    }
    else {
        foreach my $position (0 .. $self->[1] - 1) {
            push(@elements, Python2::Type::Scalar::Num->new($self->[0] + $position * $self->[2]));
        }
    }

    return @elements;
}

1;