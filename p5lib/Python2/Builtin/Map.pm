package Python2::Builtin::Map;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

use List::Util qw(max);

sub __name__ { 'map' }
sub __call__ {
    shift @_; # $self - unused

    # second argument is the function to call
    my $function        = shift @_;
    my $named_arguments = pop @_; # unsed but still get's passed

    # all remaining arguments are iterables that will be passed, in parallel, to the function
    # if one iterable has fewer items than the others it will be passed with None (undef)
    #
    # figure out the largest argument and use that to iterate over
    my $iterable_item_count = max( map { $_->__len__->__tonative__ } @_);

    # number of iterable arguments passed to map()
    my $argument_count      = scalar @_;

    my $result = Python2::Type::List->new();

    for (my $i = 0; $i < $iterable_item_count; $i++) {
        # iterables to be passed to $function. first one gets modified
        my @iterables = map {
            $_[$_]->__getitem__(Python2::Type::Scalar::Num->new($i), {})
        } (0 .. $argument_count-1 );

        $result->__setitem__(
            Python2::Type::Scalar::Num->new($i),
            $function->__call__(@iterables, bless({}, 'Python2::NamedArgumentsHash'))
        );
    }

    return $result;
}

1;
