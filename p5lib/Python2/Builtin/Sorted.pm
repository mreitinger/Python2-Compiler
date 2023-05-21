package Python2::Builtin::Sorted;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'sorted' }
sub __call__ {
    shift @_; # $self - unused
    my $named_arguments = pop @_;

    my $key = exists $named_arguments->{key} ? ${ $named_arguments->{key} } : undef;

    die Python2::Type::Exception->new('TypeError', 'key passed to sorted is not callable (does not support __call__)')
        if defined $key and not $key->can('__call__');

    return $key
        ?   \Python2::Type::List->new( sort {
                ${ $key->__call__($a, bless({}, 'Python2::NamedArgumentsHash')) }->__tonative__
                cmp
                ${ $key->__call__($b, bless({}, 'Python2::NamedArgumentsHash')) }->__tonative__
            } $_[0]->ELEMENTS )

        :   \Python2::Type::List->new(
                sort { $a->__tonative__ cmp $b->__tonative__
            } $_[0]->ELEMENTS )

        ;
};

1;
