package Python2::Builtin::Exception;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'exception' }
sub __call__ { \Python2::Type::Exception->new('Exception', $_[1]); };

1;
