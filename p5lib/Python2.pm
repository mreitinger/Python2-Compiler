package Python2;
use v5.26.0;
use warnings;
use strict;

# set a variable on our stack
sub setvar {
    my ($stack, $name, $value) = @_;
    $stack->{vars}->{$name} = $value;
}

# receive a variable from our stack
sub getvar {
    my ($stack, $name) = @_;
    return $stack->{vars}->{$name};
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
                    ($_ =~ m/^\d+$/ ? $_ : "'$_'") .  # TODO add a quote-like-python function
                    ': ' .
                    ($var->{$_} =~ m/^\d+$/ ? $var->{$_} : "'$var->{$_}'")
                } sort keys %$var
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

my $builtins = {
    'sorted' => sub {
        my ($arguments) = @_;

        die ("NYI: sorted called with multiple arguments") if (scalar(@$arguments) > 1);

        return [ sort(@{ $arguments->[0] }) ];
    },

    'int' => sub {
        my ($arguments) = @_;

        die ("NYI: int called with multiple arguments") if (scalar(@$arguments) > 1);

        return int($arguments->[0]);
    },

    'print' => sub {
        my ($arguments) = @_;

        die ("NYI: print called with multiple arguments") if (scalar(@$arguments) > 1);

        Python2::py2print($arguments->[0]);
    }
};

sub call {
    my ($function_name, $arguments) = @_;

    die("Unknown function: $function_name")
        unless defined $builtins->{$function_name};

    return $builtins->{$function_name}->($arguments);
}


1;
