package Python2::Type::PerlObject;
use v5.26.0;
use warnings;
use strict;

use base qw/ Python2::Type /;
use Python2::Type::PerlSub;

use Module::Load;

use Data::Dumper;
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

    local $Data::Dumper::Maxdepth = 1;
    die "Unblessed object passed to new_from_object: " . Dumper($object)
        unless blessed($object);

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

    die Python2::Type::Exception->new('NotImplementedError', 'PerlObject of class \'' . ref($self->{object}) . "' does not implement __str__")
        unless $self->{object}->can('__str__');

    return \Python2::Type::Scalar::String->new(
        $self->{object}->__str__
    );
}

sub __print__ { ${ shift->__str__ }; }

sub __tonative__ { return shift->{object}; }

sub __eq__ {
    my ($self, $other) = @_;

    return \Python2::Type::Scalar::Bool->new(1)
        if $self->REFADDR eq $other->REFADDR;

    return \Python2::Type::Scalar::Bool->new(0)
}

sub __call__ {
    my $self = shift;

    my @argument_list = @_;

    # last argument is the hashref with named arguments
    my $named_arguments = pop(@argument_list);

    # convert all 'Python' objects to native representations
    eval {
        foreach my $argument (@argument_list) {
            die "Unblessed argument " . Dumper($argument)
                unless blessed($argument);

            die "Argument without tonative " . Dumper($argument)
                unless $argument->can('__tonative__');

            $argument = $argument->__tonative__;
        }
    };

    # If execution of the method returned errors wrap it into a Python2 style Exception
    # so the error location is correctly shown.
    die Python2::Type::Exception->new('Exception', $@) if ($@);

    # compatiblity for the existing Inline::Python2 based DTML/python-expression compiler
    if (defined $self->{object} and $self->{class} eq 'DTML::Runtime::Method') {
        return Python2::Internals::convert_to_python_type( $self->{object}->__call__(@argument_list) );
    }
    else {
        my $object = Python2::Type::PerlObject->new($self->{class});
        eval {
            $object->{object} = $self->{class}->new(@argument_list);
        };

        if ($@) {
            die Python2::Type::Exception->new('Exception', $@);
        }

        return \$object;
    }
}

sub __hasattr__ {
    my ($self, $key) = @_;

    # our wrapped object implements __hasattr__ itself, pass the request on
    return \Python2::Type::Scalar::Bool->new($self->{object}->__hasattr__($key->__tonative__))
        if ($self->{object}->can('__hasattr__'));

    # our wrapped object does not support __hasattr__ fall back to method check
    return \Python2::Type::Scalar::Bool->new($self->can($key->__tonative__));
}

sub __getattr__ {
    my ($self, $key) = @_;

    die Python2::Type::Exception->new(
        'AttributeError',
        '__getattr__() called on net yet instanciated object'
    ) unless defined $self->{object};

    # our wrapped object implements __getattr__
    if ($self->{object}->can('__getattr__')) {
        my $retval = $self->{object}->__getattr__($key->__tonative__);

        die Python2::Type::Exception->new(
            'AttributeError',
            sprintf("Attribute '%s' not found.", $key->__tonative__)
        ) unless defined $retval;

        return Python2::Internals::convert_to_python_type( $retval );
    }

    # our wrapped object does not implement __getattr__ protocol
    die Python2::Type::Exception->new(
        'NotImplementedError',
        sprintf('PerlObject of class \'' . ref($self->{object}) . "' does not implement __getattr__, unable to handle __getattr__('%s')", $key->__tonative__)
    ) unless $self->{object}->can('__getattr__');
}

sub __getitem__ {
   my ($self, $key) = @_;

   die Python2::Type::Exception->new(
       'AttributeError',
       '__getitem__() called on net yet instanciated object'
   ) unless defined $self->{object};

   # our wrapped object implements __getitem__
   if ($self->{object}->can('__getitem__')) {
       say STDERR "X__getitem__(" . $key->__tonative__ . ") on " . ref($self->{object});
       my $retval = $self->{object}->__getitem__($key->__tonative__);

       die Python2::Type::Exception->new(
           'AttributeError',
           sprintf("Attribute '%s' not found on '%s'.", $key->__tonative__, ref($self->{object}))
       ) unless defined $retval;

       return Python2::Internals::convert_to_python_type( $retval );
   }

   # our wrapped object does not implement __getitem__
   die Python2::Type::Exception->new(
       'NotImplementedError',
       sprintf('PerlObject of class \'' . ref($self->{object}) . "' does not implement __getitem__, unable to handle __getitem__('%s')", $key->__tonative__)
   );
}



# we might have multiple instances of PerlObject around but the all reference the same
# actual perl object. return the refaddr of the wrapped object so comparisons (A == B) work as
# expected.
sub REFADDR {
    my ($self, $key) = @_;

    return refaddr($self->{object});
}

sub __len__ {
    my ($self) = @_;

    die Python2::Type::Exception->new('NotImplementedError', 'PerlObject of class \'' . ref($self->{object}) . "' does not implement __str__, unable to handle __len__")
        unless $self->{object}->can('__str__');

    return \Python2::Type::Scalar::Num->new(length $self->{object}->__str__);
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

    confess("Python2::NamedArgumentsHash missing when calling perl5 method $requested_method on " . ref($self->{object}))
        unless ref($named_arguments) eq 'Python2::NamedArgumentsHash';

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
