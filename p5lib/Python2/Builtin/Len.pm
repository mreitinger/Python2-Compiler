package Python2::Builtin::Len;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'len' }
sub __call__ {
    shift @_; # $self - unused
    pop   @_; # default named arguments hash - unused

    shift->__len__;
};

1;
