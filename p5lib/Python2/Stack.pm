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

sub new {
    my ($self, $parent, $locals) = @_;

    return bless([
        $parent,
        $locals
            ? $locals
            : Python2::Stack::Frame->new(undef)
    ], $self);
}

sub get {
    my ($self, $name) = @_;

    # if it's not a ::Frame it was supplied by overriding globals/locals so we need to convert
    # it to a python type
    my $retval = ref($self->[1]) eq 'Python2::Stack::Frame'
        ? $self->[1]->__getattr__($name)
        : Python2::Internals::convert_to_python_type( $self->[1]->__getattr__($name) );

    return $retval;
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

sub parent { return shift->[0]; }

1;
