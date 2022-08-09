package Python2::Builtin::Sorted;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'sorted' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused

    \Python2::Type::List->new( sort { $a->__tonative__ cmp $b->__tonative__ } (@{ $_[0] }) );
};

1;
