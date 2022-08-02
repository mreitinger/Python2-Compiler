package Python2::Builtin::Next;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'next' }
sub __call__ { $_[1]->__next__(); };

1;
