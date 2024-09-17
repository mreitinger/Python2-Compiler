package Python2::Builtin::Range;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'range' }
sub __call__ {
    shift @_; # $self - unused
    pop @_; # named arguments hash

    die Python2::Type::Exception->new('TypeError', 'range() expected at least one parameter, got 0')
        unless @_;

    my ($arg_1, $arg_2, $arg_3) = @_;

    die Python2::Type::Exception->new('TypeError', 'range() integer expected as first argument, got ' . (defined $arg_1 ? $arg_1->__type__ : 'nothing'))
        unless defined $arg_1 and $arg_1->__type__ eq 'int';

    die Python2::Type::Exception->new('TypeError', 'range() integer expected as second argument, got ' . $arg_2->__type__)
        if defined $arg_2 and $arg_2->__type__ ne 'int';

    die Python2::Type::Exception->new('TypeError', 'range() integer expected as third argument, got ' . $arg_2->__type__)
        if defined $arg_2 and $arg_2->__type__ ne 'int';

    if (defined $arg_1 and not defined $arg_2 and not defined $arg_3) {
        return Python2::Type::List->new(
            map { Python2::Type::Scalar::Num->new($_) } (0 .. $arg_1->__tonative__-1)
        );
    }

    if (defined $arg_1 and defined $arg_2 and not defined $arg_3) {
        return Python2::Type::List->new(
            map { Python2::Type::Scalar::Num->new($_) } ($arg_1->__tonative__ .. $arg_2->__tonative__-1)
        );
    }

    my @list;
    my $i = $arg_1->__tonative__;
    my $end = $arg_2->__tonative__;
    my $step = $arg_3->__tonative__;
    while ($i <= $end) {
        push @list, Python2::Type::Scalar::Num->new($i);
        $i += $step;
    }
    return Python2::Type::List->new(@list);
};

1;
