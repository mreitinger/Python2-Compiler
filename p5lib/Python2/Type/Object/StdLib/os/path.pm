package Python2::Type::Object::StdLib::os::path;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;


sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins],
    }, $self);

    return $object;
}

sub exists {
    my ($self, $pstack, $path) = @_;
    return \Python2::Type::Scalar::Bool->new(-e $path)
}

1;
