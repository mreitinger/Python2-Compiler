package Python2::Builtin::Compile;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'compile' }
sub __call__ {
    shift @_; # $self - unused
    my $code = shift @_;
    shift @_; # named arguments hash - unused

    die Python2::Type::Exception->new('NetImplementedError', 'compile() with parameters not implemented') if $@;

    return \$result;
}

1;
