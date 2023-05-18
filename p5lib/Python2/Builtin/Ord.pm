package Python2::Builtin::Ord;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'ord' }
sub __call__ {
    shift @_; # $self - unused
    pop   @_; # default named arguments hash - unused

    die Python2::Type::Exception->new('TypeError', 'ord() takes exactly one argument, got ' . @_)
        unless @_ == 1;

    die Python2::Type::Exception->new('TypeError', 'ord() expected string of length 1 but '. $_[0]->__type__ . ' found')
        unless $_[0]->__type__ eq 'str';

    my $value = $_[0]->__tonative__;

    die Python2::Type::Exception->new('TypeError', 'ord() expected string of length 1 but string with length ' . length($value) . ' found')
        unless length($value) == 1;

    return \Python2::Type::Scalar::Num->new(ord($value));
};

1;
