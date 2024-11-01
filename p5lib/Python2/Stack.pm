# base class for our stack
# implemetns __getattr__/__hasattr__ but expects a plain perl scalar not Python2::Type::Scalar::String
# for performance reasons.

# when overriding our stack (for example when providing local/globals for compiled expressions)
# a perl module implementing __getattr__/__hasattr__ can be used instead.

package Python2::Stack;

use v5.26.0;
use warnings;
use strict;

use Python2::Internals;
use Scalar::Util qw(blessed);

sub new {
    my ($self, $parent, $locals) = @_;

    return bless([
        $parent,
        $locals
            ? $locals
            : Python2::Stack::Frame->new(undef)
    ], $self);
}

sub get : lvalue {
    my ($self, $name, $gracefully) = @_;

    # if it's not a ::Frame it was supplied by overriding globals/locals so we need to convert
    # it to a python type
    ref($self->[1]) eq 'Python2::Stack::Frame'
        ? $self->[1]->__getattr__($name, $gracefully)
        : Python2::Internals::convert_to_python_type( $self->[1]->__getattr__($name, $gracefully) );
}

sub set {
    my ($self, $name, $value) = @_;

    $self->[1]->__setattr__($name, $value);
}

sub has {
    my ($self, $name) = @_;

    return $self->[1]->__hasattr__($name) ? 1 : 0;
}

sub delete {
    my ($self, $name) = @_;

    $self->[1]->__delattr__($name);
}

# 'clear' the all local elements (for example at the beginning of every function body)
sub clear {
    my $self = shift;
    $self->[1] = Python2::Stack::Frame->new(undef);
}

sub clone {
    my $self = shift;
    return Python2::Stack->new(
        $self->[0], Python2::Stack::Frame->new(%{ $self->[1] })
    );
}

sub parent { return shift->[0]; }

1;
