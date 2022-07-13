package Python2::Type::Scalar::None;
use v5.26.0;
use base qw/ Python2::Type::Scalar /;
use warnings;
use strict;

sub new {
    my ($self, $value) = @_;

    return bless([], $self);
}

sub __str__         { 'None'; }
sub __tonative__    { undef; }
sub __type__        { return 'none'; }

1;
