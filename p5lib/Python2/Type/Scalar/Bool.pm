package Python2::Type::Scalar::Bool;
use v5.26.0;
use base qw/ Python2::Type::Scalar::Num /;
use warnings;
use strict;

sub new {
    my ($self, $value) = @_;

    $value = $value ? 1 : 0;
    return bless \$value, $self;
}

sub __str__         { return $_[0]->$* ? 'True' : 'False'; }
sub __print__       { return $_[0]->$* ? 'True' : 'False' }
sub __tonative__    { return $_[0]->$* ? 1 : undef; }
sub __type__        { return 'bool'; }
sub __negate__      { return \__PACKAGE__->new(not $_[0]->$*); }

sub __is_py_true__  { $_[0]->$*; }

1;
