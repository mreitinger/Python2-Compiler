package Python2::Type::Object::StdLib::re::match;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self, $groups) = @_;

    my $object = bless({
        stack  => [$Python2::builtins],
        groups => $groups
    }, $self);

    return $object;
}

sub group {
    pop(@_); #default named args hash
    my ($self, $index) = @_;

    my $i = $index->__tonative__;
    die Python2::Type::Exception->new('IndexError', 'no such group: ' . $i)
        unless $index->__type__ eq 'int' && $i >= 0 && $i < scalar(@{ $self->{groups} });

    return Python2::Type::Scalar::String->new($self->{groups}->[$i]);
}

sub groups {
    my ($self) = @_;

    return Python2::Type::List->new(
        # Skip first group as that's the complete match which Python omits from groups
        map { Python2::Type::Scalar::String->new($_) }
        @{ $self->{groups}->[1 .. (@{ $self->{groups} } - 1)] }
    )
}

sub __is_py_true__ {
    1;
}

1;
