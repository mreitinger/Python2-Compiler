package Python2::Type::Object;
use Python2;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;
use Scalar::Util qw/ refaddr /;

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$builtins] }, $self);

    die if $object->can('__init__');

    $object->__build__; #TODO wrong: this should be run on class creation

    # {} for unused named variables
    $object->__init__({}) if $object->can('__init__');

    return $object;
}

sub can {
    my ($self, $method_name) = @_;

    # TODO this will return true even if the stack item
    # TODO is not a method.

    if (defined $self->{stack}->[1]->{$method_name}) {
        return 1;
    }
}

sub __getattr__ {
    my ($self, $attribute_name) = @_;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    return \$self->{stack}->[1]->{$attribute_name->__tonative__};
}

sub __str__ {
    my $self = shift;
    return sprintf('<PythonObject at %s>', refaddr($self));
}

sub AUTOLOAD {
    my $self = shift;
    my @argument_list = @_;

    our $AUTOLOAD;
    my $requested_method = $AUTOLOAD;
    $requested_method =~ s/.*:://;

    # TODO should call the equivalent python method if this object has one
    return if ($requested_method eq 'DESTROY');

    my $method_code_ref = $self->{stack}->[1]->{$requested_method} // die("Unknown method $requested_method");
    return $method_code_ref->($self, @argument_list);
}

sub __type__ { return 'pyobject'; }

1;
