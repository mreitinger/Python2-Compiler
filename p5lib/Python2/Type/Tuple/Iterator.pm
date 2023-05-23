package Python2::Type::Tuple::Iterator;

use v5.26.0;
use warnings;
use strict;

use base qw/ Python2::Type::List::Iterator /;

sub __type__ { 'tupleiterator' }

1;