package Python2::Type::PerlSub;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2::Internals;

sub new {
    my ($self, $coderef) = @_;

    my $object = bless([$coderef], $self);

    return $object;
}

sub __call__ {
    my ($self, @argument_list) = @_;

    # last argument is the hashref with named arguments
    my $named_arguments = pop(@argument_list);

    die Python2::Type::Exception->new('TypeError', "expected named arguments hash when calling perl5 coderef")
        unless ref($named_arguments) eq 'Python2::NamedArgumentsHash';

    # convert all 'Python' objects to native representations
    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__;
    }

    foreach my $argument (keys %$named_arguments) {
        $named_arguments->{$argument} = ${$named_arguments->{$argument}}->__tonative__;
    }

    my @retval;
    eval {
        # This matches the calling conventions for Inline::Python so Perl code written to work with
        # Inline::Python can keep working as-is.
        @retval = scalar keys %$named_arguments
            ? $self->[0]->([@argument_list], $named_arguments)
            : $self->[0]->(@argument_list);
    };

    # If execution of the method returned errors wrap it into a Python2 style Exception
    # so the error location is correctly shown.
    die Python2::Type::Exception->new('Exception', $@) if $@;

    die Python2::Type::Exception->new('NotImplementedError', "Got invalid return value with multiple values when calling perl5 coderef")
        if scalar(@retval) > 1;

    return Python2::Internals::convert_to_python_type($retval[0]);
}

sub __str__ {
    my $self = shift;
    return sprintf('<perlsub anon at %i>', refaddr($self));
}

sub __tonative__ { ...; }

sub __getattr__ {
    my ($self, $attr) = @_;

    die Python2::Type::Exception->new(
        'NotImplementedError',
        "__getattr__('$attr') not implemented for PerlSub"
    );
}

sub __type__ { return 'perlsub'; }

1;
