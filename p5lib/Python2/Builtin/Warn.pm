package Python2::Builtin::Warn;

use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'die' }
sub __call__ {
    my $self = shift @_; # $self - unused
    pop   @_; # default named arguments hash - unused

    print STDERR join(", ", @_) . "\n";
};

1;

