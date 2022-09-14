package Python2::Builtin::Open;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'open' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused
    my $mode = ref($_[1]) eq 'Python2::Type::Scalar::String' ? $_[1]->__tonative__ : 'r';
    \Python2::Type::File->new($_[0], $mode);
};

1;
