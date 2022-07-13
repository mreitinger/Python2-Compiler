package Python2::Type::Scalar;
use v5.26.0;
use base qw/ Python2::Type /;
use warnings;
use strict;

sub new {
    my ($self, $value) = @_;

    return bless({
        value => $value,
    }, $self);
}

# value formatted for print()
sub __print__ { return shift->{value}; }

# 'native' perl5 representation. used, for example, for sorting since __str__ would confuse
# it by adding quotes.
sub __tonative__ {
    return shift->{value};
}

sub __type__ { return 'scalar'; }

1;
