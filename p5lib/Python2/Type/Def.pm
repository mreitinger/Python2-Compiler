package Python2::Type::Def;

use v5.26.0;
use warnings;
use strict;

use base qw/ Python2::Type::Function /;

sub new {
    my ($self, $pstack, $name, $code) = @_;

    return bless({
        stack => Python2::Stack->new($pstack),
        name => $name,
        code => $code,
    }, $self);
}

sub __name__ {
    my ($self) = @_;

    return $self->{name};
}

sub __call__ {
    my $self = shift;

    return $self->{code}->($self, @_);
}

1;
