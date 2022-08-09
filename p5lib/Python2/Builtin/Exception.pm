package Python2::Builtin::Exception;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'exception' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused

    \Python2::Type::Exception->new('Exception', $_[0]);
};

1;
