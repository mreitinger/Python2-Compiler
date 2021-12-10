package Python2;
use warnings;
use strict;

# set a variable on our stack
sub setvar {
    my ($stack, $name, $value) = @_;
    $stack->{$name} = $value;
}

# receive a variable from our stack
sub getvar {
    my ($stack, $name) = @_;
    return $stack->{$name};
}

1;
