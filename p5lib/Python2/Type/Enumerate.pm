package Python2::Type::Enumerate;
use v5.26.0;
use warnings;
use strict;

use Python2::Type::Tuple;
use Python2::Type::Scalar::Num;

sub new {
    my ($self, $iterable) = @_;

    # TODO validate iterable

    return bless([0, $iterable], $self);
}

sub next {
    my $self = shift;

    die Python2::Type::Exception->new('StopIteration', 'StopIteration')
        if ($self->[0]+1 > ${ $self->[1]->__len__ }->__tonative__);

    return \Python2::Type::Tuple->new(
        Python2::Type::Scalar::Num->new($self->[0]),
        ${ $self->[1]->__getitem__(Python2::Type::Scalar::Num->new($self->[0]++) ) }
    );
}

# returnes the *remaining* elements
sub ELEMENTS {
    my ($self) = @_;

    my @elements = $self->[1]->ELEMENTS;

    my @retval = @elements[$self->[0] .. @elements-1];
    $self->[0] = @elements;

    my $i = 0;
    return map {
        Python2::Type::Tuple->new(
            Python2::Type::Scalar::Num->new($i++),
            $_,
        )
    } @retval;

}



sub __type__ { 'enumerate' }

1;