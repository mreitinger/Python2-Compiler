package Python2::Type::Scalar::Bool;
use v5.26.0;
use base qw/ Python2::Type::Scalar::Num /;
use warnings;
use strict;

sub new {
    my ($self, $value) = @_;

    return bless({
        value => $value ? 1 : 0,
    }, $self);
}

sub __str__         { return shift->{value} ? 'True' : 'False'; }
sub __print__       { return shift->{value} ? 'True' : 'False' }
sub __tonative__    { return shift->{value}; }
sub __type__        { return 'bool'; }
sub __negate__      { return \__PACKAGE__->new(not shift->{value}); }

sub __is_py_true__  { shift->{value}; }

1;
