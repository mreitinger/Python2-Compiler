package Python2::Type::List::Iterator;
use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, $list) = @_;

    return bless([0, $list], $self);
}

sub __type__ { 'listiterator' }

sub next {
    my $self = shift;

    die Python2::Type::Exception->new('StopIteration', 'StopIteration')
        if ($self->[0]+1 > $self->[1]->__len__->__tonative__);

    return $self->[1]->__getitem__(Python2::Type::Scalar::Num->new($self->[0]++) );
}

# returnes the *remaining* elements
sub ELEMENTS {
    my ($self) = @_;

    my @elements = $self->[1]->ELEMENTS;

    my @retval = @elements[$self->[0] .. @elements-1];
    $self->[0] = @elements;

    return @retval;
}

1;
