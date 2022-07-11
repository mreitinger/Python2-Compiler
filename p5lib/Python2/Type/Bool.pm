package Python2::Type::Bool;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

sub new {
    my ($self, $value) = @_;

    return bless({
        value => $value ? 1 : 0,
    }, $self);
}

sub __str__         { return shift->{value} ? "'True'" : "'False'"; }
sub __print__       { return shift->{value} ? 'True' : 'False' }
sub __tonative__    { return shift->{value}; }

1;