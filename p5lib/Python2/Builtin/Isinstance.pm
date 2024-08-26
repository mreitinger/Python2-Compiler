package Python2::Builtin::Isinstance;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'isinstance' }
sub __call__ {
    shift @_; # $self - unused
    pop   @_; # default named arguments hash - unused

    my $left = shift;
    my $right = shift;

    # compatibility hack with existing code: we use unicode everywhere but
    # the existing code might assume otherwise so we treat them all as equal
    # for isinstance() checks
   return Python2::Type::Scalar::Bool->new(1) if (
            $left->__type__ =~ m/^(str|basestring|unicode)$/
        and $right->__type__ =~ m/^(str|basestring|unicode)$/
    );

    return Python2::Type::Scalar::Bool->new($left->__type__ eq $right->__type__);
};

1;
