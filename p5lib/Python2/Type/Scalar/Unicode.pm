package Python2::Type::Scalar::Unicode;
use v5.26.0;
use base qw/ Python2::Type::Scalar::String /;
use warnings;
use strict;

sub __type__ { 'unicode'; }

1;
