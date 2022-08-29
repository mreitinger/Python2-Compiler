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

    die Python2::Type::Exception->new('NotImplementedError', "named arguments not supported when calling perl5 coderef")
        if scalar(%$named_arguments);


    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__;
    }

    my @retval = $self->[0]->(@argument_list);
    return Python2::Internals::convert_to_python_type($retval[0]);
}

sub __str__ {
    my $self = shift;
    return sprintf('<perlsub anon at %i>', refaddr($self));
}

sub __tonative__ { ...; }

sub __type__ { return 'perlsub'; }

1;
