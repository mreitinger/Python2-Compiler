package Python2::Builtin::Die;

use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'die' }
sub __call__ {
    my $self = shift @_; # $self - unused
    pop   @_; # default named arguments hash - unused

    die Python2::Type::Exception->new('Exception', @_);
};

1;

