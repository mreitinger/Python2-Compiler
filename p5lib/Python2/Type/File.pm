package Python2::Type::File;
use Python2;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;
use Scalar::Util qw/ refaddr openhandle /;

sub new {
    my ($self, $path) = @_;

    die Python2::Type::Exception->new('TypeError', 'open expects a string as path, got ' . $path->__type__)
        unless $path->__type__ eq 'str';

    open(my $fh, $path->__tonative__)
        or die Python2::Type::Exception->new('IOError', "unable to open '$path': '$!'");

    my $object = bless([$fh], $self);

    return $object;
}

sub read {
    pop(@_); #default named args hash

    my ($self, $bytes) = @_;

    die Python2::Type::Exception->new('ValueError', "I/O operation on closed file")
        unless defined openhandle($self->[0]);

    $bytes ||= Python2::Type::Scalar::Num->new(-s $self->[0]);

    die Python2::Type::Exception->new('TypeError', 'read expects a int as length, got ' . $bytes->__type__)
        unless $bytes->__type__ eq 'int';

    my $res;
    read($self->[0], $res, $bytes->__tonative__);

    return Python2::convert_to_python_type($res);
}

sub close {
    close(shift->[0]);
}

sub __type__ { return 'file'; }

1;
