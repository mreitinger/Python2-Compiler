package Python2::Builtin::Sorted;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'sorted' }
sub __call__ {
    shift @_; # $self - unused
    my $named_arguments = pop @_;

    my $list = shift @_;
    my $key     = exists $named_arguments->{key} ? $named_arguments->{key} : undef;
    my $reverse = exists $named_arguments->{reverse} ? $named_arguments->{reverse} : undef;

    die Python2::Type::Exception->new('TypeError', 'sorted expectes a list, dict, tuple, enumerate or iterable, got ' . (defined $list ? $list->__type__ : 'nothing'))
        unless defined $list and $list->__type__ =~ m/^(list|listiterator|tupleiterator|enumerate|tuple|dict)$/;

    die Python2::Type::Exception->new('TypeError', 'Value passed to sorted must be bool or int, got ' . $reverse->__type__)
        if defined $reverse and $reverse->__type__ !~ m/^(int|bool)$/;

    die Python2::Type::Exception->new('TypeError', 'key passed to sorted is not callable (does not support __call__)')
        if defined $key and not $key->can('__call__');

    $list = $list->keys() if $list->__type__ eq 'dict';

    # both bool and int work here
    $reverse = defined $reverse ? $reverse->__tonative__ : 0;

    my @result = $key
        ?   sort {
                $key->__call__($a, bless({}, 'Python2::NamedArgumentsHash'))->__tonative__
                cmp
                $key->__call__($b, bless({}, 'Python2::NamedArgumentsHash'))->__tonative__
            } $list->ELEMENTS

        :   sort {
                if($a->__lt__($b)->__tonative__) {
                    return -1;
                }
                elsif ($a->__eq__($b)->__tonative__) {
                     return 0;
                }
                else {
                     return 1;
                }
            } $list->ELEMENTS
        ;

    return $reverse
        ? Python2::Type::List->new( reverse @result )
        : Python2::Type::List->new( @result );

};

1;
