package Python2::Builtin::Dump;

use base qw/ Python2::Type::Function /;
use v5.26.0;
use warnings;
use strict;

sub __name__ { 'dump' }
sub __call__ {
    my $self = shift @_; # $self - unused
    pop   @_; # default named arguments hash - unused
    my $object = $_[0];
    my $depth  = $_[1] // Python2::Type::Scalar::Num->new(3);

    die Python2::Type::Exception->new('TypeError', 'dump expects a integer as depth, got ' . $depth->__type__)
        unless ($depth->__type__ eq 'int');

    my $dumper = Data::Dumper->new([$object]);

    $dumper->Maxdepth($depth->__tonative__);
    return Python2::Type::Scalar::String->new($dumper->Dump());
};

1;

