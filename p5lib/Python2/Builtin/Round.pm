package Python2::Builtin::Round;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'round' }
sub __call__ {
    shift(@_); # $self - unused
    pop(@_);   # default named arguments hash

    my ($value, $precision) = @_;

    $precision ||= Python2::Type::Scalar::Num->new(0);

    die Python2::Type::Exception->new('TypeError', 'a number is required as value')
        unless ($value->__class__ eq 'Python2::Type::Scalar::Num');

    die Python2::Type::Exception->new('TypeError', 'a number is required as precision')
        unless ($precision->__type__ eq 'int');

    my $retval = sprintf(
        sprintf('%%.%if', $precision->__tonative__),
        $value->__tonative__
    );

    $retval = "$retval.0" if $retval =~ m/^\d+$/;
    $retval =~ s/([1-9])0+$/$1/;

    return \Python2::Type::Scalar::Num->new($retval);
};

1;
