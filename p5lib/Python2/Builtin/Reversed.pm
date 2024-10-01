package Python2::Builtin::Reversed;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'reversed' }
sub __call__ {
    shift @_; # $self - unused
    my $named_arguments = pop @_;

    my $list = shift @_;

    die Python2::Type::Exception->new('TypeError', 'reversed expectes a list, dict, tuple, enumerate or iterable, got ' . (defined $list ? $list->__type__ : 'nothing'))
        unless defined $list and $list->__type__ =~ m/^(list|listiterator|tupleiterator|enumerate|tuple|dict)$/;

    $list = $list->keys() if $list->__type__ eq 'dict';

    return Python2::Type::List->new(reverse $list->ELEMENTS);

};

1;
