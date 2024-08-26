package Python2::Type::Object::StdLib::urllib;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use URI::Escape qw/ uri_escape_utf8 /;

use LWP::UserAgent ();

use Python2::Type::Object::StdLib::urllib::addinfourl;

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$Python2::builtins] }, $self);

    return $object;
}

sub quote {
    pop(@_); # default named arguments hash
    my ($self, $string, $safe) = @_;
    # TODO: handle safe characters? (no usage so far)
    # this might get complicated, uri_escape takes the opposite
    my $unsafe = "^A-Za-z0-9\-\._";
    my $escaped = uri_escape_utf8($string->__tonative__, $unsafe);

    return Python2::Type::Scalar::String->new($escaped);
}

sub quote_plus {
    pop(@_); # default named arguments hash
    my ($self, $string, $safe) = @_;
    # TODO: handle safe characters? (no usage so far)
    # this might get complicated, uri_escape takes the opposite
    my $unsafe = "^A-Za-z0-9\-\._ ";
    my $escaped = uri_escape_utf8($string->__tonative__, $unsafe);
    $escaped =~ s/ /+/g;

    return Python2::Type::Scalar::String->new($escaped);
}

sub urlopen {
    pop(@_); # default named arguments hash
    my ($self, $url, $data, $timeout, $cafile, $capath, $cadefault, $context) = @_;

    # very simple url open ignoring all parameters as long they're not needed
    my $ua = LWP::UserAgent->new(timeout => 10);

    my $response = $ua->get($url->__tonative__);

    return Python2::Type::Object::StdLib::urllib::addinfourl->new($response);
}



1;
