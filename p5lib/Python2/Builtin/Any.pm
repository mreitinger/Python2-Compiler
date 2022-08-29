package Python2::Builtin::Any;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'any' }
sub __call__ {
    shift @_; # $self - unused
    shift @_; # parent stack - unused
    pop @_;   # named arguments hash

    my $iterable = shift @_;

    die Python2::Type::Exception->new('TypeError', 'any() expects a list, got ' . $iterable->__type__)
        unless ($iterable->__type__ eq 'list');

    foreach my $element (@$iterable) {
        return \Python2::Type::Scalar::Bool->new(1) if $element->__is_py_true__;
    }

    return \Python2::Type::Scalar::Bool->new(0);
}

1;
