package Python2::Type::Object::StdLib::xml::etree::Element;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, $dom) = @_;

    die Python2::Type::Exception->new('Exception', 'Element->new() called without dom argument')
        unless defined $dom and ref($dom) eq 'XML::LibXML::Element';

    return bless({
        dom         => $dom,
        attributes  => Python2::Internals::convert_to_python_type(
            {
                map { $_->nodeName => $_->getValue } $dom->attributes
            }
        ),
    }, $self);
}

sub __getattr__ {
    my $self = shift;
    my $named_arguments = pop;
    my $attribute_name = shift;

    die Python2::Type::Exception->new('TypeError', '__getattr__() expects a str, got ' . (defined $attribute_name ? $attribute_name->__type__ : 'nothing'))
        unless defined $attribute_name and $attribute_name->__type__ eq 'str';

    $attribute_name = $attribute_name->__tonative__;

    return $self->{attributes} if $attribute_name eq 'attrib';
    return Python2::Type::Scalar::String->new( $self->{dom}->textContent() ) if $attribute_name eq 'text';

    die Python2::Type::Exception->new('AttributeError', "Element for node '" . $self->{dom}->nodeName . "' has no attribute '$attribute_name'");
}

sub find {
    my $self = shift;
    my $named_arguments = pop;
    my $match = shift;

    die Python2::Type::Exception->new('TypeError', 'find() expects a str as match, got ' . (defined $match ? $match->__type__ : 'nothing'))
        unless defined $match and $match->__type__ eq 'str';

    my $node = $self->{dom}->find($match);

    return defined $node
        ? Python2::Type::Object::StdLib::xml::etree::Element->new($node->shift)
        : Python2::Type::Scalar::None->new();
}

sub findall {
    my $self = shift;
    my $named_arguments = pop;
    my $match = shift;

    die Python2::Type::Exception->new('TypeError', 'findall() expects a str as match, got ' . (defined $match ? $match->__type__ : 'nothing'))
        unless defined $match and $match->__type__ eq 'str';

    return Python2::Type::List->new(
        map {
            Python2::Type::Object::StdLib::xml::etree::Element->new($_)
        } $self->{dom}->findnodes($match->__tonative__)
    );
}

sub __tonative__ {
    return shift;
}

1;
