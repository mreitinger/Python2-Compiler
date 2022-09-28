package Python2::Type::Object::StdLib::xml::etree::ElementTree;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use XML::Parser;

use Python2::Type::Object::StdLib::xml::etree::Element;

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
    my ($self, $source, $parser) = @_;

    die Python2::Type::Exception->new('OSError', 'No such file or directory: ' . $source)
        unless (-e $source);
    my $p = XML::Parser->new(Style => 'Tree');
    my $tree = $p->parsefile($source);

    return \Python2::Type::Object::StdLib::xml::etree::ElementTree->new($tree);
}

sub getroot {
    pop(@_); # default named arguments hash
    my ($self, $pstack) = @_;

    return \Python2::Type::Object::StdLib::xml::etree::Element->new(
        $self->{tree}->[0], $self->{tree}->[1]
    );
}

1;
