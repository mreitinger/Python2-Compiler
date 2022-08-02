package Python2::Builtin::Open;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'open' }
sub __call__ { \Python2::Type::File->new($_[1]); };

1;
