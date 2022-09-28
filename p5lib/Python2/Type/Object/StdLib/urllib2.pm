package Python2::Type::Object::StdLib::urllib2;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use LWP::UserAgent ();

use Python2::Type::Object::StdLib::urllib::addinfourl;

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$Python2::builtins] }, $self);

    return $object;
}

sub urlopen {
    pop(@_); # default named arguments hash
    my ($self, $url, $data, $timeout, $cafile, $capath, $cadefault, $context) = @_;

    # very simple url open ignoring all parameters as long they're not needed
    my $ua = LWP::UserAgent->new(timeout => 10);

    my $response = $ua->get($url->__tonative__);

    return \Python2::Type::Object::StdLib::urllib::addinfourl->new($response);
}

1;
