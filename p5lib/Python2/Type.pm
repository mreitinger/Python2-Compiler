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
sub __str__     { ...; }
sub __dump__    { warn Dumper(shift); }
sub __class__   { ref(shift); }
sub __type__    { ...; }

sub __cmp__     { ...; }
sub __eq__      { ...; } # ==

# !=
sub __ne__      {
    my ($self, $other) = @_;

    return ${ $self->__eq__($other) }->__tonative__
        ? \Python2::Type::Scalar::Bool->new(0)
        : \Python2::Type::Scalar::Bool->new(1);
}


sub __lt__      { ...; } # <
sub __gt__      { ...; } # >
sub __le__      { ...; } # <=
sub __ge__      { ...; } # >=

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
