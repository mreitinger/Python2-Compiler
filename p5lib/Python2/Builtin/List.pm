package Python2::Builtin::List;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'list' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused
    pop   @_; # default named arguments hash - unused

    my $value = $_[0] // Python2::Type::List->new();

    # TODO python allows more like passing a dict results in a list of the keys
    die Python2::Type::Exception->new('TypeError', 'list() expects some iterable, got ' . $value->__type__)
        unless $value->can('__iter__');

    return \Python2::Type::List->new(@{ $value });
};

1;
