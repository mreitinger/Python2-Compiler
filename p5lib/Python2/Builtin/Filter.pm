package Python2::Builtin::Filter;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'filter' }
sub __call__ {
    my ($self, $filter, $list) = @_;

    my $result = Python2::Type::List->new();

    if ($filter->__type__ eq 'none') {
        foreach(@$list) {
            $result->__iadd__($_) if $_->__tonative__;
        }
    }
    else { ...; }

    return \$result;
}

1;
