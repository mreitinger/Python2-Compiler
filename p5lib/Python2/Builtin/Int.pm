package Python2::Builtin::Int;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'int' }
sub __call__ { \Python2::Type::Scalar::Num->new(int($_[1]->__tonative__)); }

1;
