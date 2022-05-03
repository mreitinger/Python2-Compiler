package Python2;
use v5.26.0;
use warnings;
use strict;
use List::Util qw( max );
use List::Util::XS; # ensure we use the ::XS version

use Scalar::Util qw/ looks_like_number /;
use Clone qw/ clone /;
use Carp qw/ confess /;

use Python2::Type::List;
use Python2::Type::Dict;

use Exporter qw/ import /;
our @EXPORT = qw/
    getvar              setvar          compare
    call                py2print        arithmetic
    register_function   create_class    $builtins
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
                return \Python2::Type::List->new( sort(@{ $_[0]->elements }) );
            },

            'map' => sub {
                # first argument is the function to call
                my $function    = shift @_;

                # all remaining arguments are iterables that will be passed, in parallel, to the function
                # if one iterable has fewer items than the others it will be passed with None (undef)
                #
                # figure out the largest argument and use that to iterate over
                my $iterable_item_count = max( map { $_->__len__ } @_);

                # number of iterable arguments passed to map()
                my $argument_count      = scalar @_;

                my $result = Python2::Type::List->new();

                for (my $i = 0; $i < $iterable_item_count; $i++) {
                    # iterables to be passed to $function. first one gets modified
                    my @iterables = map { ${$_[$_]->element($i)} } (0 .. $argument_count-1 );

                    $result->__setitem__($i, ${ $function->(@iterables) });
                }

                return \$result;
            },

            'int' => sub {
                return \int($_[0]);
            },

            'print' => sub {
                my $arguments = shift // [];

                die ("NYI: print called with multiple arguments") if (scalar(@$arguments) > 1);

                Python2::py2print($arguments->[0]);
            },
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
        $var->print;
    }
    elsif (ref($var) eq '') {
        say $var;
    }
    else {
        confess("not implemented for " . ref($var));
    }
}

my $comparisons = {
    '==' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left == $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '!=' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left != $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '>' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left > $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '<' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left < $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '>=' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left >= $right);
        } else {
            die("comparison net yet implemented");
        }
    },

    '<=' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left <= $right);
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

my $arithmetic_operations = {
    '+' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left + $right);
        }

        # this, unlike python, allows things like "print 1 + 'a'"
        # avoiding this by doing harsher checks against perl's internals hinders
        # interoperability with other perl objects
        elsif (!looks_like_number($left) or !looks_like_number($right)) {
            return \($left.$right);
        }
        else {
            die("unsupported operand type(s) for '+'.");
        }
    },

    '-' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left - $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '*' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left * $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '/' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left / $right);
        } else {
            die("arithmetic op not yet implemented");
        }
    },

    '%' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \($left % $right);
        }

        # this, unlike python, allows things like "print 1 + 'a'"
        # avoiding this by doing harsher checks against perl's internals hinders
        # interoperability with other perl objects
        elsif (!looks_like_number($left) or !looks_like_number($right)) {
            return \sprintf($left, $right);
        }
        else {
            die("arithmetic op not yet implemented");
        }
    },
};

sub arithmetic {
    my ($left, $right, $operator) = @_;

    return $arithmetic_operations->{$operator}->($left, $right)
        if defined $arithmetic_operations->{$operator};

    die("arithmetic_operations for $operator not yet implemented");
}


1;
