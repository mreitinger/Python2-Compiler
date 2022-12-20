package Python2::Builtin::Filter;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'filter' }
sub __call__ {
    shift @_; # $self - unused

    my ($filter, $list) = @_;

    my $result = Python2::Type::List->new();

    if ($filter->__type__ eq 'none') {
        foreach(@$list) {
            $result->__iadd__($_) if $_->__tonative__;
        }
    }
    elsif ($filter->__type__ eq 'function') {
        foreach ($list->ELEMENTS) {
            $result->__iadd__($_) if ${ $filter->__call__($_, {}) }->__is_py_true__;
        }
    }
    else {
        die Python2::Type::Exception->new('TypeError', 'filter() expects None or a function, got ' . $filter->__type__);
    }

    return \$result;
}

1;
