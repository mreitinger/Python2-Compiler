package Python2::Builtin::Chr;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'chr' }
sub __call__ {
    shift @_; # $self - unused
    pop @_;   # named arguments hash - unused
    my $value = shift;

    die Python2::Type::Exception->new('TypeError', 'chr() expects an integer, got nothing')
        unless defined $value;

    die Python2::Type::Exception->new('TypeError', 'chr() expects an integer, got ' . $value->__type__)
        unless $value->__type__ eq 'int';

    return Python2::Internals::convert_to_python_type(chr($value));
};

1;
