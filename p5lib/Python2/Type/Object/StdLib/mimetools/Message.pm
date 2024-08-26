# Currently this only handles urllib's info() and has no support for anything other than HTTP responses

package Python2::Type::Object::StdLib::mimetools::Message;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;


sub new {
    my ($self, $message) = @_;


    die Python2::Type::Exception->new('TypeError', 'mimetools.Message() only implements support for HTTP::Response, got ' . defined $message ? ref($message) : 'nothing')
        unless defined $message and ref($message) eq 'HTTP::Response';

    my $object = bless({
        response => $message,
    }, $self);

    return $object;
}

sub getheader {
    my ($self, $header) = @_;

    die Python2::Type::Exception->new('TypeError', 'getheader() expects a string as header name, got ' . defined $header ? $header->__type__ : 'nothing')
        unless defined $header and $header->__type__ eq 'str';

    return defined $self->{response}->header($header->__tonative__)
        ? Python2::Type::Scalar::String->new($self->{response}->header($header->__tonative__))
        : Python2::Type::Scalar::None->new();
}

sub get {
    my ($self, @args) = @_;

    $self->getheader(@args);
}

1;
