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

sub element {
    my ($self, $key, $target) = @_;

    if ($target) {
        # array slice
        my $key     = $key->__tonative__;
        my $target  = $target->__tonative__;

        # if the target is longer than the list cap it
        if ($target > ${ $self->__len__ }->__tonative__ ) {
            $target = ${ $self->__len__}->__tonative__;
        }

        return \Python2::Type::List->new( @{ $self->{elements} }[$key .. $target - 1] );
    }
    else {
        # single element
        return \$self->{elements}->[$key->__tonative__];
    }
}

sub set {
    my ($self, $key, $value) = @_;

    $self->{elements}->[$key] = $value;
}

sub __len__ {
    my ($self) = @_;

    return \Python2::Type::Scalar->new(scalar @{ $self->{elements} });
}

sub __setitem__ {
    my ($self, $key, $value) = @_;

    $self->{elements}->[$key] = $value;
}

# convert to a 'native' perl5 arrayref
sub __tonative__ {
    return [
        map { ref($_) ? $_->__tonative__ : $_ } @{ shift->elements }
    ];
}

1;
