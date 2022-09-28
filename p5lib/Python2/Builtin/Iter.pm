package Python2::Builtin::Iter;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'iter' }
sub __call__ {
    shift @_; # $self - unused

    $_[0]->__iter__();
};

1;
