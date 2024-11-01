# This is based on Tie::RefHash see https://perldoc.perl.org/Tie::RefHash#CONTRIBUTORS
#
# This is free software; you can redistribute it and/or modify it under the same terms
# as the Perl 5 programming language system itself.

package Tie::PythonDict;

use Scalar::Util;

use Tie::Hash;
our @ISA = qw(Tie::Hash);

use warnings;
use strict;
use Carp ();

sub TIEHASH {
    my $class   = shift;
    my $self    = bless([], $class);

    while (@_) {
        $self->STORE(shift, shift);
    }

    return $self;
}


sub FETCH {
    my($self, $key) = @_;

    die("PythonDict expects as Python2::Type as key") unless (ref($key) =~ m/^Python2::Type::/);

    if (ref($key) =~ m/^Python2::Type::Scalar/) {
        return $self->[1]{$key->__str__}->[1];
    }
    elsif ($key->isa('Python2::Type::Object')) {
        my $kstr = Scalar::Util::refaddr($key);
        if (defined $self->[0]{$kstr}) {
            return $self->[0]{$kstr}[1];
        }
        else {
            return undef;
        }
    }
}

sub STORE {
    my($self, $key, $value) = @_;

    die("PythonDict expects as Python2::Type as key") unless (ref($key) =~ m/^Python2::Type::/);
    die("PythonDict expects as Python2::Type as value") unless (ref($value) =~ m/^Python2::Type::/);

    # $self->[0] contains refaddr -> object mappings
    # $self->[1] contains string -> object mappings (only for Scalar types)

    if (ref($key) =~ m/Python2::Type::Scalar/) {
        # we got a scalar key so we store both the object refaddr and the scalar key's value
        # as key.

        if (exists $self->[1]->{$key->__str__}) {
            # a value with the same key already exists, remove it otherwise
            # we would have duplicate entries for the same stringified key (but with different
            # refaddr's)
            delete $self->[0]->{Scalar::Util::refaddr($self->[1]{$key->__str__}[0])};
        }

        # store the new stringified key
        $self->[1]{$key->__str__} = [$key, $value];
    }

    # store the object address
    $self->[0]{Scalar::Util::refaddr($key)} = [$key, $value];

    return $value;
}

sub DELETE {
    my($self, $key) = @_;

    die("PythonDict expects as Python2::Type as key")   unless (ref($key) =~ m/^Python2::Type::/);

    if (ref($key) eq 'Python2::Type::Scalar') {
        delete $self->[1]{$key->__str__};
    }

    delete $self->[0]{Scalar::Util::refaddr($key)};
}

sub EXISTS {
    my($self, $key) = @_;

    if (exists($self->[0]{Scalar::Util::refaddr($key)})) {
        return $self->[0]{Scalar::Util::refaddr($key)};
    }

    if ((ref($key) =~ m/Python2::Type::Scalar/) and (exists $self->[1]{$key->__str__})) {
        return exists $self->[1]{$key->__str__};
    }
}

sub FIRSTKEY {
    my $s = shift;

    keys %{$s->[0]};  # reset iterator
    #$s->[2] = 0;      # flag for iteration, see NEXTKEY

    $s->NEXTKEY;
}

sub NEXTKEY {
    my $self = shift;

    my ($key, $value) = each %{$self->[0]};

    unless ($value) {
        return undef;
    }

    return $value->[0]; # the original key
}

sub CLEAR           {
    my $self = shift;
    $self->[2] = 0;

    %{$self->[0]} = ();
    %{$self->[1]} = ();
}

sub STORABLE_freeze { ...; }
sub STORABLE_thaw   { ...; }
sub CLONE           { ...; }

1;
