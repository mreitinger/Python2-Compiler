package Python2::Builtin::Isinstance;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'list' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused
    pop   @_; # default named arguments hash - unused

    my $left = shift;
    my $right = shift;

    return \Python2::Type::Scalar::Bool->new($left->__type__ eq $right->__type__);
};

1;
