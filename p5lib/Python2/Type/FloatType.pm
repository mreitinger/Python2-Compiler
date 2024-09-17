package Python2::Type::FloatType;
use base qw/ Python2::Type::Type /;
use v5.26.0;
use warnings;
use strict;

use Scalar::Util qw/ looks_like_number /;

sub new {
    my ($self) = @_;

    return bless(['float'], $self);
}

sub __call__    {
    shift @_; # $self - unused

    my $val = $_[0]->__tonative__;

    # insert leading zero as python does, if needed
    $val =~ s/^()\./0\./;

    die Python2::Type::Exception->new('ValueError', 'invalid literal for float(): ' . $val)
        unless (looks_like_number($val));

    # we cheat and only have a single Type::Num instead of dedicated int/float types
    # append '.0' to make Num return float if float() would otherwise return a plain
    # integer
    return $val =~ m/^\d+$/
        ? Python2::Type::Scalar::Num->new($val . '.0')
        : Python2::Type::Scalar::Num->new($val)
}

sub __type__  { return $_[0][0]; }

1;
