package Python2::Type::Object::StdLib::base;

use Python2;
use Python2::Internals;

use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;
use Scalar::Util qw/ refaddr /;
use Python2::Type::PythonMethod;

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$Python2::builtins, {}] }, $self);

    return $object;
}

sub __str__ {
    my $self = shift;
    return sprintf('<PythonObject at %s>', refaddr($self));
}

sub __hasattr__ {
    my $self = shift;
    my $named_arguments = pop;
    my $attribute_name = shift;

    die Python2::Type::Exception->new('TypeError', '__hasattr__() expects a str, got ' . (defined $attribute_name ? $attribute_name->__type__ : 'nothing'))
        unless defined $attribute_name and $attribute_name->__type__ eq 'str';

    $attribute_name = $attribute_name->__tonative__;

    return Python2::Type::Scalar::Bool->new(
        defined $self->{stack}->[1]->{$attribute_name}
        || $self->can($attribute_name)
        ? 1 : 0
    );
}

sub __getattr__ {
    my $self = shift;
    my $named_arguments = pop;
    my $attribute_name = shift;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . (defined $attribute_name ? $attribute_name->__type__ : 'nothing'))
        unless defined $attribute_name and $attribute_name->__type__ eq 'str';

    $attribute_name = $attribute_name->__tonative__;

    return $self->{stack}->[1]->{$attribute_name}
        if defined $self->{stack}->[1]->{$attribute_name};

    return Python2::Type::PythonMethod->new($self->can($attribute_name), $self)
        if $self->can($attribute_name);

    die Python2::Type::Exception->new('AttributeError', "'" . ref($self) . "' has no attribute '$attribute_name'");
}

sub __setattr__ {
    my $self = shift;
    my $named_arguments = pop;
    my $attribute_name = shift;
    my $attribute_value = shift;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . (defined $attribute_name ? $attribute_name->__type__ : 'nothing'))
        unless defined $attribute_name and $attribute_name->__type__ eq 'str';

    $attribute_name = $attribute_name->__tonative__;

    return $self->{stack}->[1]->{$attribute_name} = $attribute_value;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $requested_method = $AUTOLOAD;
    $requested_method =~ s/.*:://;

    return if ($requested_method eq 'DESTROY');

    die("Unknown method $requested_method caller was " . join(", ", caller));
}

sub __type__ { return 'pyobject'; }

1;
