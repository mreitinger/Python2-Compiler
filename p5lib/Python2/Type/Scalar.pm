package Python2::Type::Scalar;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

use overload
    bool     => sub { return $_[0]->__is_py_true__ ? 'true-from-python' : undef; },
    '""'     => sub { return $_[0]->$*; },
    fallback => 1; # Required for older Perl's - fixed with (at latest) 5.36.

sub new {
    my ($self, $value) = @_;

    return bless \$value, $self;
}

# value formatted for print()
sub __print__ { return $_[0]->$*; }

# 'native' perl5 representation. used, for example, for sorting since __str__ would confuse
# it by adding quotes.
sub __tonative__ {
    return $_[0]->$*;
}

sub __eq__ {
    my ($self, $other) = @_;

    die Python2::Type::Exception->new('Exception', 'Scalar->__eq__() called without $other')
        unless defined $other;

    return Python2::Type::Scalar::Bool->new(0)
        if $other->__type__ eq 'none';

    #return Python2::Type::Scalar::Bool->new(0)
    #    if $other->__type__ ne $self->__type__;

    return Python2::Type::Scalar::Bool->new($self->__tonative__ eq $other->__tonative__);
}

sub __len__ {
    return Python2::Type::Scalar::Num->new(length($_[0]->$*));
}

# is - used for our X is Y implementation, python2 has no explicit __is__
sub __is__  {
    my ($self, $other) = @_;

    # when compared to anything that's not our type it must be false
    return Python2::Type::Scalar::Bool->new(0)
        unless $self->__class__ eq $other->__class__;

    # if it's a scalar we compare values by default. ::Type::None overrides this.
    if ($self->__tonative__ eq $other->__tonative__) {
        return Python2::Type::Scalar::Bool->new(1);
    }
    else {
        return Python2::Type::Scalar::Bool->new(0);
    }
}

1;
