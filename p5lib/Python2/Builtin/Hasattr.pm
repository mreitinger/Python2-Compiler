package Python2::Builtin::Hasattr;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'hasattr' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused

    my ($object, $key) = @_;

    die Python2::Type::Exception->new('TypeError', 'hasattr() expects a Python2 object, got ' . $object->__type__)
        unless ($object->__class__ =~ m/^Python2::Type::/);

    die Python2::Type::Exception->new('TypeError', 'hasattr() expects a string as key, got ' . $key->__type__)
        unless ($key->__type__ eq 'str');

    return $object->__hasattr__(undef, $key);
};

1;
