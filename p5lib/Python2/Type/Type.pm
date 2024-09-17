package Python2::Type::Type;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2::Internals;
use Scalar::Util qw/ refaddr /;

sub new {
    my ($self, $type) = @_;

    return bless([$type], $self);
}

sub __getattr__ {
    my ($self, $attr) = @_;

    return Python2::Type::Scalar::String->new(shift->[0])
        if $attr eq '__name__';

    die Python2::Type::Exception->new('AttributeError', "'" . ref($self) . "' has no attribute '$attr'");
}

sub __print__ { sprintf("<type '%s'>", shift->[0]); }
sub __type__  { return 'type'; }

sub __eq__  {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new(refaddr($self) == refaddr($other) ? 1 : 0);
}

sub __ne__  {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new(refaddr($self) != refaddr($other) ? 1 : 0);
}

1;
