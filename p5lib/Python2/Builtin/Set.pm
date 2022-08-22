package Python2::Builtin::Set;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'set' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused
    pop   @_; # default named arguments hash - unused

    my $value = $_[0] // Python2::Type::List->new();

    # TODO python allows more like passing a dict results in a set of the keys
    die Python2::Type::Exception->new('TypeError', 'set() expects a list, got ' . $value->__type__)
        unless ($value->__type__ eq 'list');

    return \Python2::Type::Set->new(@{ $value });
};

1;
