package Python2::Type::Object::StdLib::re::pattern;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, $regex) = @_;

    my $object = bless({
        stack => [$Python2::builtins, {
            regex => $regex
        }]
    }, $self);

    return $object;
}

sub match {
    my ($self, $value) = @_;

    die Python2::Type::Exception->new('TypeError', 'match() expected string, got ' . $value->__type__)
        unless $value->__type__ eq 'str';

    return Python2::Type::Scalar::Bool->new(
        $value->__tonative__ =~ $self->{stack}->[1]->{regex}
    );
}

sub sub {
    my $self = shift;
    my $named_arguments = pop;
    my $replacement = shift;
    my $string = shift;

    die Python2::Type::Exception->new('TypeError', 'sub() expected string, got ' . (defined $string ? $string->__type__ : 'nothing'))
        unless defined $string and $string->__type__ eq 'str';

    die Python2::Type::Exception->new('TypeError', 'sub() expected replacement, got ' . (defined $replacement ? $replacement->__type__ : 'nothing'))
        unless defined $replacement and $replacement->__type__ eq 'str';

    die Python2::Type::Exception->new('NotImplementedError', 'sub() flags not implemented')
        if keys %$named_arguments;

    my $regex    = $self->{stack}->[1]->{regex};
    $string      = $string->__tonative__;
    $replacement = $replacement->__tonative__;

    $string =~ s/$regex/$replacement/g;

    return Python2::Type::Scalar::String->new($string);
}

1;
