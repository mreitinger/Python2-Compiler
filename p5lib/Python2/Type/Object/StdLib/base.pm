package Python2::Type::Object::StdLib::base;

use Python2;
use Python2::Internals;

use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;
use Scalar::Util qw/ refaddr /;

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$Python2::builtins] }, $self);

    return $object;
}

sub __str__ {
    my $self = shift;
    return sprintf('<PythonObject at %s>', refaddr($self));
}

sub __getattr__ {
    my ($self, $pstack, $attribute_name) = @_;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . $attribute_name->__type__)
        unless ($attribute_name->__type__ eq 'str');

    $attribute_name = $attribute_name->__tonative__;

    return \$self->{stack}->[1]->{$attribute_name}
        if defined $self->{stack}->[1]->{$attribute_name};

    die Python2::Type::Exception->new('AttributeError', "'" . ref($self) . "' has no attribute '$attribute_name'");
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my $requested_method = $AUTOLOAD;
    $requested_method =~ s/.*:://;

    return if ($requested_method eq 'DESTROY');

    die("Unknown method $requested_method");
}

sub __type__ { return 'pyobject'; }

1;
