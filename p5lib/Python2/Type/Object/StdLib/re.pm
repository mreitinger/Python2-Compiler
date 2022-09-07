package Python2::Type::Object::StdLib::re;

use base qw/ Python2::Type::Object::StdLib::base /;

use Python2::Type::Object::StdLib::re::pattern;

use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [
            $Python2::builtins,
            {
                VERBOSE     => Python2::Type::Scalar::Num->new('64'),
                IGNORECASE  => Python2::Type::Scalar::Num->new('2'),
            }
        ],
    }, $self);

    return $object;
}

sub compile {
    my ($self, $pstack, $regex, $named_args) = @_;

    my $flags = '';

    if (exists $named_args->{flags}) {
        my @flags;

        die Python2::Type::Exception->new('TypeError', sprintf("sub expects flags as integer, got %s", $named_args->{flags}->__type__))
            unless ${ $named_args->{flags} }->__type__ eq 'int';

        push(@flags, 'i') if ${ $named_args->{flags} } & 2;
        push(@flags, 'x') if ${ $named_args->{flags} } & 64;

        $flags .= join('', @flags);
    }

    return \Python2::Type::Object::StdLib::re::pattern->new(qr/(?$flags)$regex/);
}

sub sub {
    my ($self, $pstack, $regex, $newtext, $value, $named_args) = @_;

    my $flags = '';

    if (exists $named_args->{flags}) {
        my @flags;

        die Python2::Type::Exception->new('TypeError', sprintf("sub expects flags as integer, got %s", $named_args->{flags}->__type__))
            unless ${ $named_args->{flags} }->__type__ eq 'int';

        push(@flags, 'i') if ${ $named_args->{flags} } & 2;
        push(@flags, 'x') if ${ $named_args->{flags} } & 64;

        $flags .= join('', @flags);
    }

    $value = $value->__tonative__;
    $value =~ s/(?$flags)$regex/$newtext/g;

    return \Python2::Type::Scalar::String->new($value);
}

1;
