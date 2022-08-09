package Python2::Builtin::Open;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'open' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused

    \Python2::Type::File->new($_[0]);
};

1;
