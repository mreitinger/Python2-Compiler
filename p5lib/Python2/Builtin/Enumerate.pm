package Python2::Builtin::Enumerate;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'enumerate' }
sub __call__ { \Python2::Type::Enumerate->new($_[1]); };

1;
