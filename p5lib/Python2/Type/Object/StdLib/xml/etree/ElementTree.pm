package Python2::Type::Object::StdLib::xml::etree::ElementTree;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use XML::LibXML;

use Python2::Type::Object::StdLib::xml::etree::Element;

sub new {
    my ($self, $dom) = @_;

    my %namespace_prefixes;
    if ($dom) {
        foreach my $node ($dom->findnodes('//namespace::*')) {
            $namespace_prefixes{$node->getValue()} = $node->getLocalName();
        }
    }

    my $object = bless({
        stack => [
            $Python2::builtins,
            {
                VERSION => Python2::Type::Scalar::String->new('1.2.0'),
                _namespace_map => Python2::Type::Dict->new(),
            }
        ],
        dom   => $dom,
        namespace_prefixes => \%namespace_prefixes,
    }, $self);

    return $object;
}

sub parse {
    pop(@_); # default named arguments hash
    my $self = shift;
    my $source = shift;

    die Python2::Type::Exception->new(
        'TypeError',
        'parse() expects exactly one argument, path or file-like object implementing read(). got: ' . (defined $source ? $source->__type__ : 'nothing')
    ) unless (defined $source) and (($source->__type__ eq 'str') or $source->can('read'));

    die Python2::Type::Exception->new('OSError', 'No such file or directory: ' . $source)
        if $source->__type__ eq 'str' and not -e $source;

    my $dom = $source->__type__ eq 'str'
        ? XML::LibXML->load_xml(location => $source->__tonative__)
        : XML::LibXML->load_xml(string => $source->read()->__tonative__);

    return Python2::Type::Object::StdLib::xml::etree::ElementTree->new($dom);
}

sub getroot {
    pop(@_); # default named arguments hash
    my ($self, $pstack) = @_;

    return Python2::Type::Object::StdLib::xml::etree::Element->new(
        $self->{dom}->getDocumentElement(),
        $self->{namespace_prefixes},
    );
}

sub tostring {
    my ($self, $node, $nameds) = @_;
    return $node->toString;
}

1;
