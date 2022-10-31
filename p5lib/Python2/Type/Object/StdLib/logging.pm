package Python2::Type::Object::StdLib::logging;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use JSON;

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$Python2::builtins] }, $self);

    return $object;
}

sub write_message {
    my ($self, $severity, $message) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("logging expects at least 1 argument"))
        unless defined $message;

    say STDERR join(':', $severity, $message);
}

sub info {
    my ($self, $message) = @_;

    $self->write_message('INFO', $message);
}

sub warn {
    my ($self, $message) = @_;

    $self->write_message('WARNING', $message);
}

sub warning {
    my ($self, $message) = @_;

    $self->write_message('WARNING', $message);
}

sub critical {
    my ($self, $message) = @_;

    $self->write_message('CRITICAL', $message);
}

sub error {
    my ($self, $message) = @_;

    $self->write_message('ERROR', $message);
}

1;
