package Python2;
use v5.26.0;
use warnings;
use strict;
use Scalar::Util qw/ looks_like_number /;
use Clone qw/ clone /;

use Python2::Type::List;
use Python2::Type::Dict;

use Exporter qw/ import /;
our @EXPORT = qw/
    getvar              setvar          setvar_e
    call                py2print        compare
    register_function   create_class    $builtins
/;

use constant {
    PARENT  => 0,
    ITEMS   => 1,
};

# set a variable on our stack
sub setvar {
    my ($stack, $name, $value) = @_;

    $stack->[ITEMS]->{$name} = $value;
}

sub setvar_e {
    my ($stack, $name, $element, $value) = @_;

    $stack->[ITEMS]->{$name}->set($element, $value);
}

# receive a variable from our stack
sub getvar {
    my ($stack, $name) = @_;

    until (exists $stack->[ITEMS]->{$name} or not defined $stack->[PARENT]) {
        $stack = $stack->[PARENT];
    }

    # TODO we are going to need a decent exception object here
    die("NameError: name '$name' is not defined")
        unless exists $stack->[ITEMS]->{$name};

    return $stack->[ITEMS]->{$name};
}

# print like python does: attempt to produce output perfectly matching Python's
# TODO use Ref::Util(::XS?)
sub py2print {
    my $var = shift;

    if (ref($var) =~ m/^Python2::Type::/) {
        $var->print;
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

    $stack->[ITEMS]->{$name} = $coderef;
}

our $builtins = {
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

    return $stack->[ITEMS]->{$function_name}->($arguments)
        if defined $stack->[ITEMS]->{$function_name};

    die("unknown function: $function_name");
}


# register a class definition on the stack
sub create_class {
    my ($stack, $name, $build) = @_;

    die("register_class called without a valid name")
        unless $name =~ m/^[a-z]+$/; # TODO python accepts a lot more here

    die("register_class expects a build coderef")
        unless ref($build) eq 'CODE';

    my $class = {
        stack => [],
    };

    # python runs the class code block on class creation time and __init__ on object creation.
    # this takes care of the class code block
    $build->($class->{stack});

    # since everything shares a namespace on the stack we need to turn object instance creation
    # into a function. this clones the class, runs the __init__ method and returns the object.
    $stack->[ITEMS]->{$name} = sub {
         my $object = clone($class);

         $object->{stack}->[ITEMS]->{__init__}->([$object])
             if exists $object->{stack}->[ITEMS]->{__init__};

         return $object;
    }
}

1;
