package Python2::Builtin::Range;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'range' }
sub __call__ {
    return \Python2::Type::List->new(1 .. $_[1]->__tonative__);
};

1;
