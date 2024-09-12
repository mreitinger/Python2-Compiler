package Python2::Type::Lambda;

use base qw/ Python2::Type::Function /;

sub new {
    my ($self, $pstack, $code) = @_;

    return bless({
        stack => Python2::Stack->new($pstack),
        code => $code,
    }, $self);
}

sub __name__ { "lambda" }

sub __call__ {
    my $self = shift;

    return $self->{code}->($self, @_);
}

1;
