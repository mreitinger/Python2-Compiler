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

    return bless(Python2::Stack->new($Python2::builtins), shift);
}

sub __is_py_true__  { 1; }

sub can {
    my ($self, $method_name) = @_;

    # TODO this will return true even if the stack item
    # TODO is not a method.

    return $self->[0]->has($method_name);
}

sub __getattr__ {
    my ($self, $attribute_name) = @_;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    return $self->[0]->get($attribute_name->__tonative__);
}

sub __setattr__ {
    pop @_; # unused named arguments
    my ($self, $attribute_name, $value) = @_;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    die Python2::Type::Exception->new('TypeError', '__setattr__() expects a value to assign, got ' . $attribute_name->__type__)
        unless defined $value;

    ${ $self->[0]->get($attribute_name->__tonative__) } = $value;
}

sub __hasattr__ {
    my ($self, $attribute_name) = @_;

    die Python2::Type::Exception->new('TypeError', '__hasattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    return \Python2::Type::Scalar::Bool->new($self->[0]->has($attribute_name->__tonative__));
}

sub __str__ {
    my $self = shift;
    return sprintf('<PythonObject at %s>', refaddr($self));
}

# creates a new object instance from this class
sub __call__ {
    my $object          = clone(shift @_);

    $object->__build__();

    # TODO - check parent stack for __init__
    # {} for unused named variables
    $object->__init__(@_) if $object->[0]->has('__init__');

    return \$object;
}

sub __build__ {}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $requested_method = $AUTOLOAD;
    $requested_method =~ s/.*:://;

    # TODO should call the equivalent python method if this object has one
    return if ($requested_method eq 'DESTROY');

    my $self = shift;       # this object

    my $method_ref = ${ $self->[0]->get($requested_method) } // die("Unknown method $requested_method");

    return $method_ref->__call__($self, @_);
}

sub __type__ { return 'pyobject'; }

sub __parent__ { return shift->[0]; }

1;
