package Python2::Type::Object::StdLib::re;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

sub sub {
    my ($self, $pstack, $regex, $newtext, $value) = @_;

    $value = $value->__tonative__;
    $value =~ s/$regex/$newtext/;

    return \Python2::Type::Scalar::String->new($value);
}

1;
