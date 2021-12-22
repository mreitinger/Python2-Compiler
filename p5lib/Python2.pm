package Python2;
use v5.26.0;
use warnings;
use strict;
use Scalar::Util qw/ looks_like_number /;
use Clone qw/ clone /;

use Python2::Type::List;

# set a variable on our stack
sub setvar {
    my ($stack, $name, $value) = @_;

    $stack->{vars}->{$name} = $value;
}

# receive a variable from our stack
sub getvar {
    my ($stack, $name) = @_;

    until (exists $stack->{vars}->{$name} or not defined $stack->{parent}) {
        $stack = $stack->{parent};
    }

    # TODO we are going to need a decent exception object here
    die("NameError: name '$name' is not defined")
        unless exists $stack->{vars}->{$name};

    return $stack->{vars}->{$name};
}

# print like python does: attempt to produce output perfectly matching Python's
# TODO use Ref::Util(::XS?)
sub py2print {
    my $var = shift;

    if (ref($var) =~ m/^Python2::Type::/) {
        $var->print;
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

my $comparisons = {
    '==' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return ($left == $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '!=' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return ($left != $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '>' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return ($left > $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '<' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return ($left < $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '>=' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return ($left >= $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '<=' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return ($left <= $right);
        } else {
            die("comparison net yet implemented");
        }
    }
};

sub compare {
    my ($left, $right, $operator) = @_;

    return $comparisons->{$operator}->($left, $right)
        if defined $comparisons->{$operator};

    die("comparison for $operator not yet implemented");
}

# register a function definition on the stack
sub register_function {
    my ($stack, $name, $coderef) = @_;

    die("register_function called without a valid name")
        unless $name =~ m/^[a-z\d_]+$/i; # TODO python accepts a lot more here

    die("register_function expects a coderef")
        unless ref($coderef) eq 'CODE';

    $stack->{funcs}->{$name} = $coderef;
}

# register a class definition on the stack
sub register_class {
    my ($stack, $name, $definition) = @_;

    die("register_class called without a valid name")
        unless $name =~ m/^[a-z]+$/; # TODO python accepts a lot more here

    die("register_class expects a definition hash")
        unless ref($definition) eq 'HASH';

    $stack->{classes}->{$name} = $definition;
}

my $builtins = {
    'sorted' => sub {
        my ($arguments) = @_;

        die("sorted() expects a list as parameter")
            unless ref($arguments->[0]) eq 'Python2::Type::List';

        return Python2::Type::List->new( sort(@{ $arguments->[0]->elements }) );
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
    my ($stack, $function_name, $arguments) = @_;

    return $builtins->{$function_name}->($arguments)
        if defined $builtins->{$function_name};

    return $stack->{funcs}->{$function_name}->($arguments)
        if defined $stack->{funcs}->{$function_name};

    return Python2::create_object($stack, $function_name)
        if defined $stack->{classes}->{$function_name};

    die("unknown function: $function_name");
}


sub create_object {
    my ($stack, $class_name) = @_;

    die("no class for $class_name") unless defined $stack->{classes}->{$class_name};

    my $object = bless($stack->{classes}->{$class_name}, "PY2::$class_name");
    $object->{init}->($object);

    return $object;
}




1;
