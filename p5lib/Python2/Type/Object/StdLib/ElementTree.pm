package Python2::Type::Object::StdLib::ElementTree;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use XML::Parser;

use Python2::Type::Object::StdLib::etree::Element;

sub new {
    my ($self, $tree) = @_;

    my $object = bless({
        stack => [$Python2::builtins],
        tree => $tree
    }, $self);

    return $object;
}

sub parse {
    pop(@_); # default named arguments hash
    my ($self, $pstack, $source, $parser) = @_;

    my $p = XML::Parser->new(Style => 'Tree');
    my $tree = $p->parsefile($source);

    return \Python2::Type::Object::StdLib::ElementTree->new($tree);
}

sub getroot {
    pop(@_); # default named arguments hash
    my ($self, $pstack) = @_;

    my $tree = $self->{tree};

    my $tag = $tree->[0];
    my $content = $tree->[1];

    return \Python2::Type::Object::StdLib::etree::Element->new($tag, $content);
}

1;
