package Python2;
use v5.26.0;
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

# print like python does: attempt to produce output perfectly matching Python's
# TODO use Ref::Util(::XS?)
sub py2print {
    my $var = shift;

    if (ref($var) eq 'ARRAY') {
        say '[' . join(', ', map { $_ =~ m/^\d+$/ ? $_ : "'$_'" } @$var) . ']';
    }
    elsif (ref($var) eq 'HASH') {
        my $output = '';

        say "{" .
            join (', ',
                map {
                    "$_: " . ($var->{$_} =~ m/^\d+$/ ? $var->{$_} : "'$var->{$_}'")
                } keys %$var
            ) .
        "}";
    }
    elsif (ref($var) eq '') {
        say $var;
    }
    else {
        die("not implemented for " . ref($var));
    }

}


1;
