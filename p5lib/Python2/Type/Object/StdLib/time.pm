package Python2::Type::Object::StdLib::time;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self) = @_;

    my $object = bless({}, $self);

    return $object;
}

sub time {
    return Python2::Type::Scalar::Num->new(time);
}

1;
