package Python2::Type::Object::StdLib::urllib::addinfourl;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Python2::Type::Object::StdLib::mimetools::Message;

sub new {
    my ($self, $response) = @_;

    my $object = bless({
        stack => [$Python2::builtins],
        response => $response   # LWP User-Agent response object
    }, $self);

    return $object;
}

sub read {
    my ($self, $pstack) = @_;

    return \Python2::Type::Scalar::String->new($self->{response}->decoded_content);
}

sub info {
    my ($self) = @_;

    return \Python2::Type::Object::StdLib::mimetools::Message->new($self->{response});
}

1;
