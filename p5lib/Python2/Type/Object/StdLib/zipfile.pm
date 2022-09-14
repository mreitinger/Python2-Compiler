package Python2::Type::Object::StdLib::zipfile;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Python2::Type::Object::StdLib::zipfile::ZipFile;

sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins, {
            ZipFile => Python2::Type::Object::StdLib::zipfile::ZipFile->new()
        }],
    }, $self);

    return $object;
}


1;
