# this module is just used as a base package for runtime ->isa('Python2::Type') checks. Used as base class by
# Python2::Type::*.

package Python2::Type;

use strict;
use warnings;
use Python2;
use Data::Dumper;
use Scalar::Util qw/ refaddr /;

use constant { PARENT => 0, ITEMS => 1 };

sub __print__   { return shift->__str__; }
sub __str__     { die Python2::Type::Exception->new('NotImplementedError', '__str__ for ' . shift->__type__); }
sub __dump__    { warn Dumper(shift); }
sub __class__   { ref(shift); }
sub __type__    { die Python2::Type::Exception->new('NotImplementedError', '__type__ for ' . ref(shift)); }

sub __cmp__     { die Python2::Type::Exception->new('NotImplementedError', '__cmp__ between ' . shift->__type__ . ' and ' . shift->__type__); }
sub __eq__      { die Python2::Type::Exception->new('NotImplementedError', '__eq__ between ' . shift->__type__ . ' and ' . shift->__type__); } # ==

# we implement this using __hasattr__ instead of (ab)using __getattr__ in case we need more
# fine control when interfacing with perl 5 objects.
sub __hasattr__ {
    my ($self, $key) = @_;

    return \Python2::Type::Scalar::Bool->new($self->can($key->__tonative__));
}

# !=
sub __ne__      {
    my ($self, $other) = @_;

    return ${ $self->__eq__($other) }->__tonative__
        ? \Python2::Type::Scalar::Bool->new(0)
        : \Python2::Type::Scalar::Bool->new(1);
}


sub __lt__      { die Python2::Type::Exception->new('NotImplementedError', '__lt__ between ' . shift->__type__ . ' and ' . shift->__type__); } # <
sub __gt__      { die Python2::Type::Exception->new('NotImplementedError', '__gt__ between ' . shift->__type__ . ' and ' . shift->__type__); } # >
sub __le__      { die Python2::Type::Exception->new('NotImplementedError', '__le__ between ' . shift->__type__ . ' and ' . shift->__type__);; } # <=
sub __ge__      { die Python2::Type::Exception->new('NotImplementedError', '__ge__ between ' . shift->__type__ . ' and ' . shift->__type__);; } # >=

# is - used for our X is Y implementation, python2 has no explicit __is__
sub __is__  {
    my ($self, $other) = @_;

    if (refaddr($self) == refaddr($other)) {
        return \Python2::Type::Scalar::Bool->new(1);
    }
    else {
        return \Python2::Type::Scalar::Bool->new(0);
    }
}

sub AUTOLOAD {
    my $self = shift;

    our $AUTOLOAD;
    my $requested_method = $AUTOLOAD;
    $requested_method =~ s/.*:://;

    return if ($requested_method eq 'DESTROY');

    die Python2::Type::Exception->new(
        'AttributeError',
        sprintf("%s instance has no attribute '%s'", 'TODO', $requested_method)
    );
}

1;
