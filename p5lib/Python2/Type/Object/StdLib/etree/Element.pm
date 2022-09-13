package Python2::Type::Object::StdLib::etree::Element;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Python2::Internals qw/ convert_to_python_type /;

sub new {
    my ($self, $tag, $content) = @_;

    my $attrs = Python2::Internals::convert_to_python_type($content->[0]);
    my $object = bless({
        stack   => [$Python2::builtins, {
            attrib  => $$attrs,
            tag     => Python2::Type::Scalar::String->new($tag)
        }],
        content => $content,

    }, $self);

    return $object;
}


1;
