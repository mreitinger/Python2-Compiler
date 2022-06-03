package Python2::Type::PerlObject;
use v5.26.0;
use warnings;
use strict;

use base qw/ Python2::Type /;

use Python2;
use Module::Load;

use Scalar::Util qw/ blessed /;

sub new {
    my ($self, $class) = @_;

    load $class;

    my $object = bless({
        object => $class->new(),
    }, $self);

    return $object;
}

sub can {
    my ($self, $method_name) = @_;

    if (defined $self->{object}->can($method_name)) {
        return 1;
    }
}

# called for every unknown method
sub AUTOLOAD {
    my ($self, @argument_list) = @_;

    # figure out the requested method
    our $AUTOLOAD;
    my $requested_method = $AUTOLOAD;
    $requested_method =~ s/.*:://; #

    # TODO do we need to pass this on to our 'child' object? probably but needs verification
    # TODO it get's called from somewhere else anyway.
    return if ($requested_method eq 'DESTROY');

    # check if our object even has the requested method
    die("Unknown method $requested_method")
        unless $self->{object}->can($requested_method);

    # last argument is the hashref with named arguments
    my $named_arguments = pop(@argument_list);

    die("named arguments not supported when calling perl5 methods")
        if scalar(%$named_arguments);


    # convert all 'Python' objects to native representations
    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__
            if (blessed($argument) and $argument->isa('Python2::Type'));
    }

    \$self->{object}->$requested_method(@argument_list);
}

1;
