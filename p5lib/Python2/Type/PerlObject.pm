package Python2::Type::PerlObject;
use v5.26.0;
use warnings;
use strict;

use base qw/ Python2::Type /;
use Python2::Type::PerlSub;

use Module::Load;

use Scalar::Util qw/ blessed refaddr /;
use Clone qw/ clone /;

sub new {
    my ($self, $class) = @_;

    load $class;

    my $object = bless({
        class  => $class,
        object => undef,
    }, $self);

    return $object;
}

sub new_from_object {
    my ($self, $object) = @_;

    return bless({
        object => $object,
    }, $self);
}

sub __is_py_true__  { 1; }

sub can {
    my ($self, $method_name) = @_;

    if (defined $self->{object}->can($method_name)) {
        return 1;
    }
}

sub __str__ {
    my $self = shift;

    return sprintf('<PerlObject %s at %s>', ref($self->{object}), refaddr($self));
}

sub __tonative__ { return shift->{object}; }

sub __eq__ {
    my ($self, $pstack, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(1)
        if (refaddr($other) eq refaddr($self));

    return \Python2::Type::Scalar::Bool->new(0)
}

sub __call__ {
    my $object = clone(shift);
    $object->{object} = $object->{class}->new();
    return \$object;
}

# called for every unknown method
sub AUTOLOAD {
    # we get the parent stack as $pstack but we don't pass it on
    my ($self, $pstack, @argument_list) = @_;

    # figure out the requested method
    our $AUTOLOAD;
    my $requested_method = $AUTOLOAD;
    $requested_method =~ s/.*:://; #

    # TODO do we need to pass this on to our 'child' object? probably but needs verification
    # TODO it get's called from somewhere else anyway.
    return if ($requested_method eq 'DESTROY');

    # check if our object even has the requested method
    die Python2::Type::Exception->new('AttributeError', 'object of class \'' . ref($self->{object}) . "' has no method '$requested_method'")
        unless $self->{object}->can($requested_method);

    # last argument is the hashref with named arguments
    my $named_arguments = pop(@argument_list);

    # we don't support named arguments but still expect the empty hash - just here to catch bugs
    die Python2::Type::Exception->new('NotImplementedError', "expected named arguments hash when calling perl5 method $requested_method on " . ref($self->{object}))
        unless ref($named_arguments) eq 'HASH';

    die Python2::Type::Exception->new('NotImplementedError', "named arguments not supported when calling perl5 methods $requested_method on " . ref($self->{object}))
        if scalar(%$named_arguments);

    # convert all 'Python' objects to native representations
    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__;
    }

    # TODO: this needs to handle way more cases like a list getting returned
    my @retval = $self->{object}->$requested_method(@argument_list);

    die Python2::Type::Exception->new('NotImplementedError', "Got invalid return value with multiple values when calling '$requested_method' on " . ref($self->{object}))
        if scalar(@retval) > 1;

    return Python2::Internals::convert_to_python_type($retval[0]);
}

sub __type__ { return 'p5object'; }

1;
