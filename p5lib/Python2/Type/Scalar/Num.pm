# we might have to split this into Int/Float/Complex

package Python2::Type::Scalar::Num;
use v5.26.0;
use base qw/ Python2::Type::Scalar /;
use warnings;
use strict;

sub __str__ { return shift->{value}; }

1;
