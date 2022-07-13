package Python2;
use v5.26.0;
use warnings;
use strict;
use List::Util qw( max );
use List::Util::XS; # ensure we use the ::XS version
use Data::Dumper;

use Scalar::Util qw/ looks_like_number blessed /;
use Clone qw/ clone /;
use Carp qw/ confess /;
use Carp::Always;

use Python2::Type::None;
use Python2::Type::Bool;
use Python2::Type::List;
use Python2::Type::Dict;
use Python2::Type::Scalar;
use Python2::Type::PerlObject;

use Exporter qw/ import /;
our @EXPORT = qw/
    getvar              setvar                  compare
    call                py2print                arithmetic
    register_function   create_class            $builtins
    getopt              convert_to_python_type
/;

use constant {
    PARENT  => 0,
    ITEMS   => 1,
};

# set a variable on our stack86:1
sub setvar {
    my ($stack, $name, $value) = @_;

    $stack->[ITEMS]->{$name} = $value;
}

sub setvar_e {
    my ($stack, $name, $element, $value) = @_;

    $stack->[ITEMS]->{$name}->set($element, $value);
}

# builtins is used as our top level stack so it must look like one
our $builtins = [
    [
        undef,
        {
            'sorted' => sub {
                return \Python2::Type::List->new( sort { $a->__tonative__ cmp $b->__tonative__ } (@{ $_[0]->elements }) );
            },

            'map' => sub {
                # first argument is the function to call
                my $function        = shift @_;
                my $named_arguments = pop @_; # unsed but still get's passed

                # all remaining arguments are iterables that will be passed, in parallel, to the function
                # if one iterable has fewer items than the others it will be passed with None (undef)
                #
                # figure out the largest argument and use that to iterate over
                my $iterable_item_count = max( map { ${ $_->__len__ }->__tonative__ } @_);

                # number of iterable arguments passed to map()
                my $argument_count      = scalar @_;

                my $result = Python2::Type::List->new();

                for (my $i = 0; $i < $iterable_item_count; $i++) {
                    # iterables to be passed to $function. first one gets modified
                    my @iterables = map {
                        ${$_[$_]->__getitem__(Python2::Type::Scalar->new($i), {}) }
                    } (0 .. $argument_count-1 );

                    $result->__setitem__(Python2::Type::Scalar->new($i), ${ $function->(@iterables, {}) });
                }

                return \$result;
            },

            'int' => sub {
                return \Python2::Type::Scalar->new(int($_[0]->__tonative__));
            },

            'range' => sub {
                return \Python2::Type::List->new(1 .. shift->__tonative__);
            },

            'print' => sub {
                my $arguments = shift // [];

                die ("NYI: print called with multiple arguments") if (scalar(@$arguments) > 1);

                Python2::py2print($arguments->[0]);
            },

            'None' => Python2::Type::None->new(),
        }
    ]
];

# return a reference to a variable name on our stack
sub getvar {
    my ($stack, $name) = @_;

    my $call_frame = $stack;

    until (exists $call_frame->[ITEMS]->{$name} or not defined $call_frame->[PARENT]) {
        $call_frame = $call_frame->[PARENT];
    }

    return $call_frame->[ITEMS]->{$name} ? \$call_frame->[ITEMS]->{$name} : \$stack->[ITEMS]->{$name};
}

# print like python does: attempt to produce output perfectly matching Python's
# TODO use Ref::Util(::XS?)
sub py2print {
    my $var = shift;

    if (ref($var) =~ m/^Python2::Type::/) {
        say $var->__print__;
    }
    else {
        confess("not implemented for " . ref($var));
    }
}

my $comparisons = {
    '==' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Bool->new($left == $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '!=' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Bool->new($left != $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '>' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Bool->new($left > $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '<' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Bool->new($left < $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '>=' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Bool->new($left >= $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '<=' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Bool->new($left <= $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    'is' => sub {
        my ($left, $right) = @_;

        return \Python2::Type::Bool->new(0)
            unless $left->__class__ eq $right->__class__;

        $left  = $left->__tonative__  if ref($left)  eq 'Python2::Type::Scalar';
        $right = $right->__tonative__ if ref($right) eq 'Python2::Type::Scalar';

        if ($left == $right) {
            return \Python2::Type::Bool->new(1);
        }
        else {
            return \Python2::Type::Bool->new(0);
        }
    }
};

sub compare {
    my ($left, $right, $operator) = @_;

    return $comparisons->{$operator}->($left, $right)
        if defined $comparisons->{$operator};

    die("comparison for $operator not yet implemented");
}


# TODO all of those should use the magic methods like python does.
# TODO This way we could skip a lot of the type checks
my $arithmetic_operations = {
    '+' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left + $right);
        }

        # this, unlike python, allows things like "print 1 + 'a'"
        # avoiding this by doing harsher checks against perl's internals hinders
        # interoperability with other perl objects
        elsif (!looks_like_number($left) or !looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left.$right);
        }
        else {
            die("unsupported operand type(s) for '+'.");
        }
    },

    '-' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left - $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '*' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left * $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '/' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left / $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '//' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left / $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '**' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left ** $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '&' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left & $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '|' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left | $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '^' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left ^ $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '>>' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left >> $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '<<' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar->new($left << $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '%' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left->__tonative__) and looks_like_number($right->__tonative__)) {
            return \Python2::Type::Scalar->new($left->__tonative__ % $right->__tonative__);
        }

        # this, unlike python, allows things like "print 1 + 'a'"
        # avoiding this by doing harsher checks against perl's internals hinders
        # interoperability with other perl objects
        elsif (!looks_like_number($left->__tonative__) or !looks_like_number($right->__tonative__)) {
            return \Python2::Type::Scalar->new(sprintf(
                $left->__tonative__,
                ref($right) eq 'Python2::Type::List'
                    ? map { $_->__print__ } @{ $right->elements }
                    : $right->__print__
            ));
        }
        else {
            die("arithmetic op not yet implemented");
        }
    },
};

sub arithmetic {
    my ($left, $right, $operator) = @_;

    # TODO - since introducing Python2::Type::Scalar we can probably handle all of this
    # TODO - with just operator overloading.
    return $arithmetic_operations->{$operator}->($left, $right)
        if defined $arithmetic_operations->{$operator};

    die("arithmetic_operations for $operator not yet implemented");
}

sub getopt {
    my ($stack, $function_name, $argument_definition, @arguments) = @_;

    # named arguments get passed as a hashref at the last position. be convention the hashref is
    # always present so it's safe to pop() it here. this ensures the hashref does not conflict
    # with any other arguments.
    my $named_arguments = pop(@arguments);

    confess unless ref($named_arguments) eq 'HASH';

    foreach my $argument (@$argument_definition) {
        my $name    = $argument->[0]; # name of this argument.
        my $default = $argument->[1]; # default value of this argument. might be undef.

        # we got a positional argument. check if it conflicts and use it otherwise.
        if (exists $arguments[0]) {
            die("$function_name(): conflict between named/positional argument '$name'")
                if exists $named_arguments->{$name};

            setvar($stack, $name, shift(@arguments));
            next;
        }

        # we got a named argument
        if (exists $named_arguments->{$name}) {
            setvar($stack, $name, ${ $named_arguments->{$name} });
            next;
        }

        # we got nothing, use the default.
        setvar($stack, $name, ${ $default });
    }
}

# converts any data structure to our 'native' "reference to a Python2::Type::* object" representation
sub convert_to_python_type {
    my ($value) = @_;

    # TODO - do introduce some kind of None type object?
    # undef
    return \Python2::Type::None->new() unless defined $value;

    # if it's already a native type just return it
    if (blessed($value) and (blessed($value) =~ m/^Python2::Type::/)) {
        return \$value;
    }

    # some foreign perl object - wrap it in our PerlObject wrapper so it conforms to our
    # calling conventions
    if (blessed($value)) {
        return \Python2::Type::PerlObject->new_from_object($value)
    }

    # perl5 hashref
    if (ref($value) eq 'HASH') {
        # TODO since perl does not support objects as hash keyes this can be optimized a lot by
        # TODO creating a dedicated "PerlDict" class and skipping all of the object-as-dict-key
        # implementation.
        my $dict = Python2::Type::Dict->new();

        while (my ($k, $v) = each(%$value)) {
            $dict->__setitem__(Python2::Type::Scalar->new($k), ${ convert_to_python_type($v) });
        }

        return \$dict;
    }

    # perl5 array
    if (ref($value) eq 'ARRAY') {
        return \Python2::Type::List->new(@$value)
    }

    # anything else must be a plain scalar
    return \Python2::Type::Scalar->new($value)
}

1;
