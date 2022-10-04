# contains the compiled code of a single python expression. used for embedding python expressions.

package Python2::Type::CodeObject;
use base qw/ Python2::Type /;
use v5.26.0;
use warnings;
use strict;

use Python2;
use Python2::Internals;
use Clone qw/ clone /;


sub new {
    my ($self, $pstack, $locals) = @_;

    return bless([Python2::Stack->new($Python2::builtins)], $self);
}

sub __call__ { ...; }
sub __name__ { ...; }

sub __str__ {
    my $self = shift;
    return sprintf('<codeobject %s at %i>', $self->__name__, refaddr($self));
}

sub __type__ { return 'codeobject'; }

1;
