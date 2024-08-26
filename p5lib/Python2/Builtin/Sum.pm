package Python2::Builtin::Sum;
use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

use List::Util qw(sum);

sub __name__ { 'sum' }
sub __call__ {
    shift @_; # $self - unused
    pop   @_; # default named arguments hash - unused

        my ($list, $start_value) = @_;

        $start_value ||= Python2::Type::Scalar::Num->new(0);

        die Python2::Type::Exception->new('TypeError', 'sum() expects a list')
            unless ($list->__class__ eq 'Python2::Type::List');

        die Python2::Type::Exception->new('TypeError', 'sum() expects a number as start_value, got ' . $start_value->__type__)
            unless ($start_value->__class__ eq 'Python2::Type::Scalar::Num');

        my @plist = map {
            die Python2::Type::Exception->new('TypeError', 'sum() found invalid list element: ' . $_->__type__)
                unless ($_->__class__ eq 'Python2::Type::Scalar::Num');

            $_->__tonative__;
        } @$list;

        my $retval = sum(@plist) + $start_value->__tonative__;

        return Python2::Type::Scalar::Num->new($retval);
};

1;
