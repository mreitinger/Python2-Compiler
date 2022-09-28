# This class is used to wrap methods that are implemented in pure Perl
#
# For performance reasons our StdLib modules are written in pure Perl without the
# Python::Type::Function/Object wrappers.
#
# PythonMethod wrappers are used if something wants to fetch the method 'attribute'.
# This wrapper keeps track of the object and method and takes care of the correct
# calling conventions. See Python2::Type::Object::StdLib::base->__getattr__() for details.

package Python2::Type::PythonMethod;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2::Internals;

sub new {
    my ($self, $coderef, $object) = @_;

    return bless([
        $coderef, $object
    ], $self);
}

sub __call__ {
    my ($self, @argument_list) = @_;

    return $self->[0]->($self->[1], @argument_list);
}

sub __str__ {
    my $self = shift;
    return sprintf('<pythonmethod anon at %i>', refaddr($self));
}

sub __tonative__ { ...; }

sub __type__ { return 'pythonmethod'; }

1;
