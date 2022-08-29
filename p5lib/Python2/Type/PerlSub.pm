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
    my ($self, $pstack, @argument_list) = @_;

    # last argument is the hashref with named arguments
    my $named_arguments = pop(@argument_list);

    # we don't support named arguments but still expect the empty hash - just here to catch bugs
    die Python2::Type::Exception->new('NotImplementedError', "expected named arguments hash when calling perl5 coderef")
        unless ref($named_arguments) eq 'HASH';


    # convert all 'Python' objects to native representations
    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__;
    }

    foreach my $argument (keys %$named_arguments) {
        $named_arguments->{$argument} = ${$named_arguments->{$argument}}->__tonative__;
    }


    # TODO: this needs to handle way more cases like a list getting returned
    # This matches the calling conventions for Inline::Python so Perl code written to work with
    # Inline::Python can keep working as-is.
    my @retval = scalar keys %$named_arguments
        ? $self->[0]->([@argument_list], $named_arguments)
        : $self->[0]->(@argument_list);

    die Python2::Type::Exception->new('NotImplementedError', "Got invalid return value with multiple values when calling perl5 coderef")
        if scalar(@retval) > 1;

    return Python2::Internals::convert_to_python_type($retval[0]);
}

sub __str__ {
    my $self = shift;
    return sprintf('<perlsub anon at %i>', refaddr($self));
}

sub __tonative__ { ...; }

sub __type__ { return 'perlsub'; }

1;
