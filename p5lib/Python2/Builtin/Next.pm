package Python2::Builtin::Next;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'next' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused

    $_[0]->__next__();
};

1;