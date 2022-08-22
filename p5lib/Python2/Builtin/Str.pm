package Python2::Builtin::Str;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'str' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused

    # TODO - this attempts to convert way more than python
    \Python2::Type::Scalar::String->new($_[0]->__tonative__);
}

1;
