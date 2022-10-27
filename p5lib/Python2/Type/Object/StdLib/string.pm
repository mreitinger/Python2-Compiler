package Python2::Type::Object::StdLib::string;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Python2::Type::Scalar::String;

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$Python2::builtins] }, $self);

    return $object;
}

sub lower {
    shift;
    return Python2::Type::Scalar::String->new(shift)->lower;
}

sub upper {
    shift;
    return Python2::Type::Scalar::String->new(shift)->upper;
}

sub replace {
    shift;
    return Python2::Type::Scalar::String->new(shift)->replace(@_);
}

sub count {
    shift;
    return Python2::Type::Scalar::String->new(shift)->count(@_);
}

sub split {
    shift;
    return Python2::Type::Scalar::String->new(shift)->split(@_);
}


1;
