package Python2::Builtin::Float;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

use Scalar::Util qw/ looks_like_number /;

sub __name__ { 'float' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused

    my $val = $_[0]->__tonative__;
    # insert leading zero as python does, if needed
    $val =~ s/^()\./0\./;
    die Python2::Type::Exception->new('ValueError',
        'invalid literal for float(): ' . $val)
        unless (looks_like_number($val));
    \Python2::Type::Scalar::Num->new($val);
}

1;
