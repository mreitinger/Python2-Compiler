package Python2;
use v5.26.0;
use warnings;
use strict;
use List::Util::XS; # ensure we use the ::XS version
use Data::Dumper;

use Scalar::Util qw/ looks_like_number blessed /;
use Clone qw/ clone /;
use Carp qw/ confess /;

use Python2::Builtin;
use Python2::Type::List;
use Python2::Type::Enumerate;
use Python2::Type::Tuple;
use Python2::Type::Dict;
use Python2::Type::File;
use Python2::Type::Scalar::String;
use Python2::Type::Scalar::Num;
use Python2::Type::Scalar::Bool;
use Python2::Type::Scalar::None;
use Python2::Type::PerlObject;
use Python2::Type::Exception;
use Python2::Type::Function;

use Exporter qw/ import /;
our @EXPORT = qw/
    getvar              setvar                  compare
    call                py2print                arithmetic
    register_function   create_class            $builtins
    getopt              convert_to_python_type  raise
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

# builtins is used as our top level stack so it must look like one
our $builtins = [
    [
        undef,
        {
            'sorted'    => Python2::Builtin::Sorted->new(),
            'int'       => Python2::Builtin::Int->new(),
            'hasattr'   => Python2::Builtin::Hasattr->new(),
            'map'       => Python2::Builtin::Map->new(),
            'range'     => Python2::Builtin::Range->new(),
            'open'      => Python2::Builtin::Open->new(),
            'iter'      => Python2::Builtin::Iter->new(),
            'next'      => Python2::Builtin::Next->new(),
            'enumerate' => Python2::Builtin::Enumerate->new(),
            'filter'    => Python2::Builtin::Filter->new(),
            'sum'       => Python2::Builtin::Sum->new(),
            'round'     => Python2::Builtin::Round->new(),

            'None'      => Python2::Type::Scalar::None->new(),
            'True'      => Python2::Type::Scalar::Bool->new(1),
            'False'     => Python2::Type::Scalar::Bool->new(0),
            'Exception' => Python2::Builtin::Exception->new(), # Exception gets a message passed so
                                                               # it is implemented as a function
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

sub raise {
    my $exception = shift;

    die("Expected a exception object")
        unless $exception->__type__ eq 'exception';

    die $exception;
}

sub py2print {
    pop(@_); # named arguments hash
    print $_->__print__ foreach(@_);
    print "\n";
}

my $comparisons = {
    '==' => sub {
        my ($left, $right) = @_;

        return \Python2::Type::Scalar::Bool->new($left->__tonative__ eq $right->__tonative__);
    },

    '!=' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Bool->new($left != $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '>' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Bool->new($left > $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '<' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Bool->new($left < $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '>=' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Bool->new($left >= $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '<=' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Bool->new($left <= $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    'is' => sub {
        my ($left, $right) = @_;

        return \Python2::Type::Scalar::Bool->new(0)
            unless $left->__class__ eq $right->__class__;

        $left  = $left->__tonative__  if ref($left)  =~ m/^Python2::Type::Scalar::/;
        $right = $right->__tonative__ if ref($right) =~ m/^Python2::Type::Scalar/;

        if ($left == $right) {
            return \Python2::Type::Scalar::Bool->new(1);
        }
        else {
            return \Python2::Type::Scalar::Bool->new(0);
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

        if ((ref($left) =~ m/^Python2::Type::Scalar::Num/) and (ref($right) =~ m/^Python2::Type::Scalar::Num/)) {
            return \Python2::Type::Scalar::Num->new($left->__tonative__ + $right->__tonative__);
        }
        elsif (($left->__type__ eq 'list') and ($right->__type__ eq 'list')) {
            return \Python2::Type::List->new(@$left, @$right)
        }

        # this, unlike python, allows things like "print 1 + 'a'"
        # avoiding this by doing harsher checks against perl's internals hinders
        # interoperability with other perl objects
        elsif ((ref($left) =~ m/^Python2::Type::Scalar/) and (ref($right) =~ m/^Python2::Type::Scalar/)) {
            return \Python2::Type::Scalar::String->new($left->__tonative__ . $right->__tonative__);
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
            return \Python2::Type::Scalar::Num->new($left - $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '*' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left * $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '/' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left / $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '//' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left / $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '**' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left ** $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '&' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left & $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '|' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left | $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '^' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left ^ $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '>>' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left >> $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '<<' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left << $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '%' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left->__tonative__) and looks_like_number($right->__tonative__)) {
            return \Python2::Type::Scalar::Num->new($left->__tonative__ % $right->__tonative__);
        }

        # this, unlike python, allows things like "print 1 + 'a'"
        # avoiding this by doing harsher checks against perl's internals hinders
        # interoperability with other perl objects
        elsif (!looks_like_number($left->__tonative__) or !looks_like_number($right->__tonative__)) {
            return \Python2::Type::Scalar::String->new(sprintf(
                $left->__tonative__,
                ref($right) eq 'Python2::Type::List'
                    ? map { $_->__print__ } @$right
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
            # TODO we should handle this at compile time
            die Python2::Type::Exception->new('SyntaxError', "$function_name(): conflict between named/positional argument '$name'")
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

    # undef
    return \Python2::Type::Scalar::None->new() unless defined $value;

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
            $k = looks_like_number($k)
                ? Python2::Type::Scalar::Num->new($k)
                : Python2::Type::Scalar::String->new($k);

            $v = looks_like_number($v)
                ? Python2::Type::Scalar::Num->new($v)
                : Python2::Type::Scalar::String->new($v);

            $dict->__setitem__($k, $v);
        }

        return \$dict;
    }

    # perl5 array
    if (ref($value) eq 'ARRAY') {
        return \Python2::Type::List->new(
            map { ${ convert_to_python_type($_) } } @$value
        );
    }

    # anything else must be a plain scalar
    return looks_like_number($value)
        ? \Python2::Type::Scalar::Num->new($value)
        : \Python2::Type::Scalar::String->new($value);
}

1;
