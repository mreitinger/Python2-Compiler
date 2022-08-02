package Python2::Builtin::Sorted;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'sorted' }
sub __call__ {
    my $iterable = $_[1];
    return \Python2::Type::List->new( sort { $a->__tonative__ cmp $b->__tonative__ } (@$iterable) );
};

1;
