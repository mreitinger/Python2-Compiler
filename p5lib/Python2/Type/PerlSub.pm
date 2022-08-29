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

    pop(@argument_list); # unused named arguments hash

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
