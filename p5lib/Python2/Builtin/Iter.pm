package Python2::Builtin::Iter;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'iter' }
sub __call__ { $_[1]->__iter__(); };

1;
