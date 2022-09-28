package Python2::Builtin::Enumerate;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'enumerate' }
sub __call__ {
    shift @_; # $self - unused

    \Python2::Type::Enumerate->new($_[0]);
};

1;
