package Python2::Type::PerlObject;
use v5.26.0;
use warnings;
use strict;

use base qw/ Python2::Type /;
use Python2::Type::PerlSub;

use Module::Load;

use Scalar::Util qw/ blessed refaddr /;

sub new {
    my $self = shift;

    # ugly hack - redirect new() to our wrapped class. TODO
    # this does not cover the 'class uses new for somthing thats not a constructor' case.

    if (ref $self) {
        my (@argument_list) = @_;
        return $self->CALL_METHOD('new', @argument_list);
    }

    # base class
    else {
        my $class = shift;

        load $class;

        my $object = bless({
            class  => $class,
            object => undef,
        }, $self);

        return $object;
    }

}

sub new_from_object {
    my ($self, $object) = @_;

    return bless({
        class  => ref($object),
        object => $object,
    }, $self);
}

sub __is_py_true__  { 1; }

sub can {
    my ($self, $method_name) = @_;

    return 1 if $method_name eq 'new';
    return 1 if $method_name eq '__tonative__';

    if ($self->{class}->can($method_name)) {
        return 1;
    }

    else {
        return 0;
    }
}

sub __str__ {
    my $self = shift;

    return sprintf('<PerlObject %s at %s>', ref($self->{object}), refaddr($self));
}

sub __tonative__ { return shift->{object}; }

sub __eq__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(1)
        if (refaddr($other) eq refaddr($self));

    return \Python2::Type::Scalar::Bool->new(0)
}

sub __call__ {
    my $self = shift;

    my $object = Python2::Type::PerlObject->new($self->{class});
    $object->{object} = $self->{class}->new();
    return \$object;
}

sub __hasattr__ {
    my ($self, $key) = @_;
    return \Python2::Type::Scalar::Bool->new($self->can($key->__tonative__));
}

# called for every unknown method
sub AUTOLOAD {
    my ($self, @argument_list) = @_;

    # figure out the requested method
    our $AUTOLOAD;
    my $requested_method = $AUTOLOAD;
    $requested_method =~ s/.*:://;

    # TODO do we need to pass this on to our 'child' object? probably but needs verification
    # TODO it get's called from somewhere else anyway.
    return if ($requested_method eq 'DESTROY');

    # check if our object even has the requested method
    unless ($self->{class}->can($requested_method)) {
        if ($requested_method eq '__getattr__') {
            # we did not find the requested method and the called object does not implemement __getattr__
            # provide a bettter error message otherwise it would just say 'has not method __getattr__'

            $requested_method = defined $argument_list[0] ? $argument_list[0]->__tonative__ : 'unknown';
        }

        die Python2::Type::Exception->new('AttributeError', 'object of class \'' . ref($self->{object}) . "' has no method '$requested_method'");
    }

    return $self->CALL_METHOD($requested_method, @argument_list);
}

sub CALL_METHOD {
    my ($self, $requested_method, @argument_list) = @_;

    # last argument is the hashref with named arguments
    my $named_arguments = pop(@argument_list);

    # we don't support named arguments but still expect the empty hash - just here to catch bugs
    die Python2::Type::Exception->new('NotImplementedError', "expected named arguments hash when calling perl5 method $requested_method on " . ref($self->{object}))
        unless ref($named_arguments) eq 'HASH';

    # convert all 'Python' objects to native representations
    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__;
    }

    foreach my $argument (keys %$named_arguments) {
        $named_arguments->{$argument} = ${$named_arguments->{$argument}}->__tonative__;
    }

    # This matches the calling conventions for Inline::Python so Perl code written to work with
    # Inline::Python can keep working as-is.

    # if we didn't get initialized beforehand redirect to the class - used for
    # object creation with constructors that are not called 'new'
    my $target = defined $self->{object} ? $self->{object} : $self->{class};

    my @retval;

    eval {
        @retval = scalar keys %$named_arguments
            ? $target->$requested_method([@argument_list], $named_arguments)
            : $target->$requested_method(@argument_list);
    };

    if ($@) {
        die Python2::Type::Exception->new('Exception', $@);
    }

    if (scalar(@retval) > 1) {
        return Python2::Internals::convert_to_python_type([@retval]);
    }
    else {
        return Python2::Internals::convert_to_python_type($retval[0]);
    }
}

sub __type__ { return 'p5object'; }

1;
