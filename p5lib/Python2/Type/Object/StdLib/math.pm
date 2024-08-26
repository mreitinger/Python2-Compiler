package Python2::Type::Object::StdLib::math;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;
use POSIX ();

sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins],
    }, $self);

    return $object;
}

sub floor {
    my $self = shift @_;
    pop @_; # unused named arguments hash
    my $value = shift @_;

    die Python2::Type::Exception->new('TypeError', 'floor() expects a number, got ' . (defined $value ? $value->__type__ : 'nothing'))
        unless defined $value and ref($value) eq 'Python2::Type::Scalar::Num';

    return Python2::Type::Scalar::Num->new( POSIX::floor($value->__tonative__) );
}

sub ceil {
    my $self = shift @_;
    pop @_; # unused named arguments hash
    my $value = shift @_;

    die Python2::Type::Exception->new('TypeError', 'ceil() expects a number, got ' . (defined $value ? $value->__type__ : 'nothing'))
        unless defined $value and ref($value) eq 'Python2::Type::Scalar::Num';

    return Python2::Type::Scalar::Num->new( POSIX::ceil($value->__tonative__) );
}



1;