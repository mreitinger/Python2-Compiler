package Python2::Type::Exception;
use v5.26.0;
use warnings;
use strict;
use Devel::StackTrace;

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
    SyntaxError => 1,
    SystemError => 1,
    SystemExit => 1,
    TypeError => 1,
    ValueError => 1,
    WindowsError => 1,
    ZeroDivisionError => 1,
};

sub new {
    my ($self, $type, $message) = @_;

    die Python2::Type::Exception->new('Exception', "Invalid exception type '$type'")
        unless exists $valid_exceptions->{$type};

    return bless([$type, $message,  Devel::StackTrace->new()], $self);
}

sub message { shift->[1] }

sub __str__  {
    my $self = shift;
    return sprintf("%s: %s", $self->[0]);
};

sub __trace__ { shift->[2] }

sub __type__ { 'exception' }

1;