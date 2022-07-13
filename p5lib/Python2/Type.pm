# this module is just used as a base package for runtime ->isa('Python2::Type') checks. Used as base class by
# Python2::Type::*.

package Python2::Type;

use strict;
use warnings;
use Python2;
use Data::Dumper;

sub __print__   { return shift->__str__; }
sub __str__     { ...; }
sub __dump__    { warn Dumper(shift); }
sub __class__   { __PACKAGE__ }
sub __type__    { ...; }

1;
