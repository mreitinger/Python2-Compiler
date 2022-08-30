package Python2::Type::Object;

use Python2;
use Python2::Internals;

use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;
use Scalar::Util qw/ refaddr /;
use Clone 'clone';

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$Python2::builtins] }, $self);

    return $object;
}

sub __is_py_true__  { 1; }

sub can {
    my ($self, $method_name) = @_;

    # TODO this will return true even if the stack item
    # TODO is not a method.

    if (defined $self->{stack}->[1]->{$method_name}) {
        return 1;
    }
}

sub __getattr__ {
    my ($self, $pstack, $attribute_name) = @_;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    return \$self->{stack}->[1]->{$attribute_name->__tonative__};
}

sub __str__ {
    my $self = shift;
    return sprintf('<PythonObject at %s>', refaddr($self));
}

# creates a new object instance from this class
# TODO handle __build__/__init__ here, see new()
sub __call__ {
    my $object = clone(shift);
    my $pstack = shift;

    $object->__build__($pstack);

    # TODO - check parent stack for __init__
    # {} for unused named variables
    $object->__init__(undef, {}) if $object->can('__init__');

    return \$object;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $requested_method = $AUTOLOAD;
    $requested_method =~ s/.*:://;

    # TODO should call the equivalent python method if this object has one
    return if ($requested_method eq 'DESTROY');

    my $self = shift;       # this object
    my $pstack = shift;     # the stack of our parent/caller

    my $method_ref = $self->{stack}->[1]->{$requested_method} // die("Unknown method $requested_method");

    return $method_ref->__call__($pstack, $self, @_);
}

sub __type__ { return 'pyobject'; }

1;
