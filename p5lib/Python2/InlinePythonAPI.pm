package Python2::InlinePythonAPI;

use common::sense;

sub py_is_tuple {
    my ($value) = @_;

    return tied(@$value) =~ m/^Tie::Tuple/ ? 1 : 0;
}

1;