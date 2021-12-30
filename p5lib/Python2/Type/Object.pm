# basic object: every object branches from here and

package Python2::Type::Object;

use v5.26.0;
use warnings;
use strict;

use Python2;

use Ref::Util qw/ is_arrayref /;

sub new {
    my ($class) = @_;

    return bless({ stack => {} }, $class);
}

sub method_call {
    my ($self, $method, $arguments) = @_;

    die("unknown method: $method")
        unless defined $self->stack->{funcs}->{$method};

    die("argument list not an ArrayRef while calling $method")
        if not is_arrayref($arguments);

    unshift(@$arguments, $self);

    $self->stack->{funcs}->{$method}->($arguments);
}

sub has_method { defined shift->stack->{funcs}->{'__init__'} }

sub stack { return shift->{stack}; }

1;
