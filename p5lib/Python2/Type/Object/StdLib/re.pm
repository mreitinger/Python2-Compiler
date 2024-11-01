package Python2::Type::Object::StdLib::re;

use base qw/ Python2::Type::Object::StdLib::base /;

use Python2::Type::Object::StdLib::re::pattern;
use Python2::Type::Object::StdLib::re::match;

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
    my ($self, $regex, $named_args) = @_;

    my $flags = '';

    if (exists $named_args->{flags}) {
        my @flags;

        die Python2::Type::Exception->new('TypeError', sprintf("sub expects flags as integer, got %s", $named_args->{flags}->__type__))
            unless $named_args->{flags}->__type__ eq 'int';

        push(@flags, 'i') if $named_args->{flags} & 2;
        push(@flags, 'x') if $named_args->{flags} & 64;

        $flags .= join('', @flags);
    }

    return Python2::Type::Object::StdLib::re::pattern->new(qr/(?$flags)$regex/);
}

sub sub {
    my ($self, $regex, $newtext, $value, $named_args) = @_;

    my $flags = '';

    if (exists $named_args->{flags}) {
        my @flags;

        die Python2::Type::Exception->new('TypeError', sprintf("sub expects flags as integer, got %s", $named_args->{flags}->__type__))
            unless $named_args->{flags}->__type__ eq 'int';

        push(@flags, 'i') if $named_args->{flags} & 2;
        push(@flags, 'x') if $named_args->{flags} & 64;

        $flags .= join('', @flags);
    }

    $value = $value->__tonative__;
    $value =~ s/(?$flags)$regex/$newtext/g;

    return Python2::Type::Scalar::String->new($value);
}


sub search {
    pop(@_); #default named args hash
    my ($self, $regex, $string) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("search() expects a string as regex as first parameter, got %s", (defined $regex ? $regex->__type__ : 'nothing')))
        unless defined $regex and $regex->__type__ eq 'str';

    die Python2::Type::Exception->new('TypeError', sprintf("search() expects a string to search as second parameter, got %s", (defined $string ? $string->__type__ : 'nothing')))
        unless defined $string and $string->__type__ eq 'str';

    my $r = $regex->__tonative__;

    my $groups = [ $string =~ /($r)/ ];

    return @$groups
        ? Python2::Type::Object::StdLib::re::match->new($groups)
        : Python2::Type::Scalar::None->new();
}

sub match {
    pop(@_); #default named args hash
    my ($self, $regex, $string) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("match() expects a string as regex as first parameter, got %s", (defined $regex ? $regex->__type__ : 'nothing') . join("|", caller)))
        unless defined $regex and $regex->__type__ eq 'str';

    die Python2::Type::Exception->new('TypeError', sprintf("match() expects a string to search as second parameter, got %s", (defined $string ? $string->__type__ : 'nothing')))
        unless defined $string and $string->__type__ eq 'str';

    my $r = $regex->__tonative__;

    # match.group(0) contains the outer match, so we simply wrap () around the expression
    my $groups = [ $string =~ /^($r)/ ];

    return @$groups
        ? Python2::Type::Object::StdLib::re::match->new($groups)
        : Python2::Type::Scalar::None->new;
}

sub findall {
    pop(@_); #default named args hash
    my ($self, $regex, $string) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("findall() expects a string as regex as first parameter, got %s", (defined $regex ? $regex->__type__ : 'nothing')))
        unless defined $regex and $regex->__type__ eq 'str';

    die Python2::Type::Exception->new('TypeError', sprintf("findall() expects a string to search as second parameter, got %s", (defined $string ? $string->__type__ : 'nothing')))
        unless defined $string and $string->__type__ eq 'str';

    my $r = $regex->__tonative__;

    my @matches;
    while ($string =~ /$r/gp) {
        my @groups = @{^CAPTURE};
        $groups[scalar @+ - 2] = undef unless @groups + 1 == @+;
        push @matches,
            @groups < 2
                ? Python2::Type::Scalar::String->new(@groups < 1 ? ${^MATCH} : $groups[0])
                : Python2::Type::Tuple->new(
                    map { Python2::Type::Scalar::String->new($_ // '') } @groups
                );
    }

    return Python2::Type::List->new(@matches);
}

1;
