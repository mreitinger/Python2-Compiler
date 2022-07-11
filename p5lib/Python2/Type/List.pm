package Python2::Type::List;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

sub new {
    my ($self, @initial_elements) = @_;

    return bless({
        elements => [ map { ${ Python2::convert_to_python_type($_) } } @initial_elements ],
    }, $self);
}

sub __str__ {
    my $self = shift;

    return '[' . join(', ', map { $_->__str__ } @{ $self->{elements} }) . ']';
}

sub elements { shift->{elements} }

sub __getitem__ {
    my ($self, $key) = @_;

    return \$self->{elements}->[$key->__tonative__];
}

sub __getslice__ {
    my ($self, $key, $target) = @_;

    $key     = $key->__tonative__;
    $target  = $target->__tonative__;

    # if the target is longer than the list cap it
    if ($target > ${ $self->__len__ }->__tonative__ ) {
        $target = ${ $self->__len__}->__tonative__;
    }

    return \Python2::Type::List->new( @{ $self->{elements} }[$key .. $target - 1] );
}

sub __len__ {
    my ($self) = @_;

    return \Python2::Type::Scalar->new(scalar @{ $self->{elements} });
}

sub __setitem__ {
    my ($self, $key, $value) = @_;

    $self->{elements}->[$key->__tonative__] = $value;
}

# convert to a 'native' perl5 arrayref
sub __tonative__ {
    return [
        map { ref($_) ? $_->__tonative__ : $_ } @{ shift->elements }
    ];
}

1;
