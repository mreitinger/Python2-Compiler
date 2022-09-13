package Python2::Type::Object::StdLib::base64;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins],
    }, $self);

    return $object;
}

sub encode {
    pop(@_); # default named arguments hash
    my ($self, $pstack, $input, $output) = @_;
    # Just a dummy to make the function importable, not called in any python script
    return Python2::Type::Scalar::None->new();
}

sub decode {
    pop(@_); # default named arguments hash
    my ($self, $pstack, $input, $output) = @_;
    # Just a dummy to make the function importable, not called in any python script
    return Python2::Type::Scalar::None->new();
}

sub b64encode {
    pop(@_); # default named arguments hash
    my ($self, $pstack, $s, $altchars) = @_;

    my $res = Python2::Type::Scalar::String->new($s)->encode($pstack, 'base64', undef);
    # string.encode leaves a trailing newline but b64encode does not
    # https://bugs.python.org/issue17714
    # so we need to remove it for equal results
    $$res =~ s/\s+$//;
    return \Python2::Type::Scalar::String->new($$res);
}

sub b64decode {
    pop(@_); # default named arguments hash
    my ($self, $pstack, $s, $altchars) = @_;

    my $res = Python2::Type::Scalar::String->new($s)->decode($pstack, 'base64', undef);
    $$res =~ s/\s+$//;
    return \Python2::Type::Scalar::String->new($$res);
}

1;
