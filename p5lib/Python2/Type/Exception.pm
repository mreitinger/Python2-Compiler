package Python2::Type::Exception;
use v5.26.0;
use warnings;
use strict;

use Devel::StackTrace;

use overload
    '""' => '__str__',

    # used so we can do "cheap" runtime checks
    'eq' => sub {
        my ($self, $expected) = @_;

        # ugly hack - match exception for everything
        return 1 if ($expected eq "Exception");

        return 1 if ($self->[0] eq $expected);
    },

    # used so we can do "cheap" runtime checks
    'ne' => sub {
        my ($self, $expected) = @_;

        # ugly hack - match exception for everything
        return 0 if ($expected eq "Exception");

        return 1 if ($self->[0] ne $expected);
    };

my $valid_exceptions = {
    Exception => 1,
    StandardError => 1,
    ArithmeticError => 1,
    LookupError => 1,
    AssertionError => 1,
    AttributeError => 1,
    EOFError => 1,
    EnvironmentError => 1,
    FloatingPointError => 1,
    IOError => 1,
    ImportError => 1,
    IndexError => 1,
    KeyError => 1,
    KeyboardInterrupt => 1,
    MemoryError => 1,
    NameError => 1,
    NotImplementedError => 1,
    OSError => 1,
    OverflowError => 1,
    ReferenceError => 1,
    RuntimeError => 1,
    StopIteration => 1,
    SyntaxError => 1,
    SystemError => 1,
    SystemExit => 1,
    TypeError => 1,
    ValueError => 1,
    ZeroDivisionError => 1,
};

sub new {
    my ($self, $type, $message) = @_;

    return $message if ref($message) eq 'Catalyst::Exception::Detach';

    die Python2::Type::Exception->new('Exception', "Invalid exception type '$type'")
        unless exists $valid_exceptions->{$type};

    # there are 3 ways Exceptions get created:
    # (1) - by Python2.pm as base exception classes with just a type
    #       this takes care of the plain 'raise Exception' (without a message getting passed)
    # (2) - by some code calling Exception('foo')
    #       this ends up with a new Exception object, handled by __call__ below
    # (3) - some internals create a new Python2::Type::Exception object from scratch

    return defined $message
        ? bless([$type, $message, Devel::StackTrace->new], $self) # handles (3)
        : bless([$type, undef, undef], $self);                    # handles (1)

}

sub __call__ {
    my ($self, $message) = @_;

    my $object          = Python2::Type::Exception->new($self->[0], $message);

    $object->[2] = Devel::StackTrace->new(),

    return $object;
}

sub message {
    my $self = shift;
    return defined $self->[1]
        ? sprintf('%s: %s', $self->[0], $self->[1])
        : $self->[0];
}

sub __str__  {
    my $self = shift;
    my $str = defined $self->[1]
        ? sprintf('%s: %s', $self->[0], $self->[1])
        : $self->[0];

    return $str;
}

sub __trace__ {
    my $self = shift;

    # if we don't get instanciated with a message we never get to __call__ and have no stacktrace
    # so we create a new one here. we cannot store this in the pseudo-exception object since
    # it might be reused
    return defined $self->[2]
        ?  $self->[2]                   # raise Exception('foo')
        : Devel::StackTrace->new()      # raise Exception
}

sub __type__ { 'exception' }

sub __print__ {
    shift->[1] // ''
}

sub __exception_type__ { $_[0]->[0] }

1;
