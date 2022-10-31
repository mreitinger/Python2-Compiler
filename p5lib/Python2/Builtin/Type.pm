package Python2::Builtin::Type;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'type' }
sub __call__ {
    shift @_; # $self - unused
    pop   @_; # default named arguments hash - unused

    my $object = shift;

    die Python2::Type::Exception->new('TypeError', 'type() takes 1 argument')
        if scalar @_;

    die Python2::Type::Exception->new('TypeError', 'type() takes 1 argument')
        unless defined $object;

    return \Python2::Type::Scalar::String->new(
        sprintf("<type '%s'>", $object->__type__)
    );
};

1;
