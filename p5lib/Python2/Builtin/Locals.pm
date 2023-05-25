package Python2::Builtin::Locals;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, $caller_stack) = @_;

    return bless({
        caller_stack => $caller_stack
    }, $self);
}

sub __name__ { 'locals' }
sub __call__ {
    my ($self) = @_;

    my $locals = Python2::Type::Dict->new();

    foreach my $key (keys %{ $self->{caller_stack}->[1] }) {
        $locals->__setitem__(
            ${ Python2::Internals::convert_to_python_type($key) },
            $self->{caller_stack}->[1]->{$key},
        );
    }

    return \$locals;
}

1;