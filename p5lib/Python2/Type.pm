# this module is just used as a base package for runtime ->isa('Python2::Type') checks. Used as base class by
# Python2::Type::*.

package Python2::Type;

use strict;
use warnings;

use Python2::Internals;

use Data::Dumper;
use Scalar::Util qw/ refaddr /;

use constant { PARENT => 0, ITEMS => 1 };

sub __print__   { return shift->__str__; }
sub __str__     { die Python2::Type::Exception->new('NotImplementedError', '__str__ for ' . shift->__type__); }

sub __dump__ {
    my $self   = shift @_;
    shift  @_; # parent stack - unused
    pop   @_; # default named arguments hash - unused

    my $depth = $_[0] // Python2::Type::Scalar::Num->new(3);

    die Python2::Type::Exception->new('TypeError', 'dumpstack expects a integer as depth, got ' . $depth->__type__)
        unless ($depth->__type__ eq 'int');

    my $dumper = Data::Dumper->new([$self]);
    $dumper->Maxdepth($depth->__tonative__);
    return \Python2::Type::Scalar::String->new($dumper->Dump());
}

sub __class__   { ref(shift); }
sub __type__    { die Python2::Type::Exception->new('NotImplementedError', '__type__ for ' . ref(shift)); }

sub __cmp__     { die Python2::Type::Exception->new('NotImplementedError', '__cmp__ between ' . $_[0]->__type__ . ' and ' . $_[2]->__type__); }
sub __eq__      { die Python2::Type::Exception->new('NotImplementedError', '__eq__ between ' . $_[0]->__type__ . ' and ' . $_[2]->__type__); } # ==

# we implement this using __hasattr__ instead of (ab)using __getattr__ in case we need more
# fine control when interfacing with perl 5 objects.
sub __hasattr__ {
    my ($self, $pstack, $key) = @_;

    return \Python2::Type::Scalar::Bool->new($self->can($key->__tonative__));
}

# !=
sub __ne__      {
    my ($self, $pstack, $other) = @_;

    return ${ $self->__eq__(undef, $other) }->__tonative__
        ? \Python2::Type::Scalar::Bool->new(0)
        : \Python2::Type::Scalar::Bool->new(1);
}

sub __is_py_true__  {
    die Python2::Type::Exception->new('NotImplementedError', '__is_py_true__ for ' . $_[0]->__type__);
}

sub __lt__          { die Python2::Type::Exception->new('NotImplementedError', '__lt__ between ' . $_[0]->__type__ . ' and ' . $_[2]->__type__); } # <
sub __gt__          { die Python2::Type::Exception->new('NotImplementedError', '__gt__ between ' . $_[0]->__type__ . ' and ' . $_[2]->__type__); } # >
sub __le__          { die Python2::Type::Exception->new('NotImplementedError', '__le__ between ' . $_[0]->__type__ . ' and ' . $_[2]->__type__);; } # <=
sub __ge__          { die Python2::Type::Exception->new('NotImplementedError', '__ge__ between ' . $_[0]->__type__ . ' and ' . $_[2]->__type__);; } # >=
sub __contains__    { die Python2::Type::Exception->new('NotImplementedError', '__contains__ between ' . $_[0]->__type__ . ' and ' . $_[2]->__type__);; } # in
sub __len__         { die Python2::Type::Exception->new('NotImplementedError', '__len__ for ' . $_[0]->__type__) };


# is - used for our X is Y implementation, python2 has no explicit __is__
sub __is__  {
    my ($self, $pstack, $other) = @_;

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
        sprintf("%s instance has no attribute '%s'", ref($self), $requested_method)
    );
}

1;
