package Python2::Internals;
use v5.26.0;
use warnings;
use strict;
use List::Util::XS; # ensure we use the ::XS version
use Data::Dumper;

use Scalar::Util qw/ looks_like_number blessed /;
use Clone qw/ clone /;
use Carp qw/ confess /;
use Module::Load;

use constant {
    PARENT  => 0,
    ITEMS   => 1,
};

# set a variable on our stack
sub setvar {
    my ($stack, $name, $value) = @_;

    $stack->[ITEMS]->{$name} = $value;
}

# delete a variable on our stack
sub delvar {
    my ($stack, $name) = @_;

    defined $stack->[ITEMS]->{$name}
        ? delete $stack->[ITEMS]->{$name}
        : die Python2::Type::Exception->new('NameError', "name '$name' not defined");
}

# return a reference to a variable name on our stack
sub getvar {
    my ($stack, $recurse, $name) = @_;

    $name = Python2::Type::Scalar::String->new($name);

    # if recursion is disabled (for variable assignment) don't travel upwards on the stack
    return $stack->__getattr__(undef, $name)
        unless $recurse;

    # recursion enabled - look upwards to find the variable
    my $call_frame = $stack;

    until (${ $call_frame->__hasattr__(undef, $name) }->__tonative__ or not defined $call_frame->__parent__) {
        $call_frame = $call_frame->__parent__;
    }

    return ${ $call_frame->__hasattr__(undef, $name) }->__tonative__
        ? $call_frame->__getattr__(undef, $name)
        : $stack->__getattr__(undef, $name);
}

sub apply_base_class {
    my $stack        = shift;       # the stack of the object we just created
    my $pstack       = shift;       # the stack of our caller
    my $base_class   = shift;       # the base class to be inherited

    # attempt to find the base class in our parent stack
    $base_class = getvar($pstack, 1, $base_class);

    # check if it really exists
    $$base_class // die Python2::Type::Exception->new("NameError", "name '%s' is not defined");

    # create a instance of our base class
    # TODO we might get by with just calling $base__class::__build__(...)
    # TODO and pass our own object
    my $base_object = $$base_class->__build__($pstack);

    # replace the stack of our object with the stack of our parent class
    @$stack = @{ clone $$base_class->{stack} };
}

sub import_module {
    my ($stack, $name) = @_;

    load "Python2::Type::Object::StdLib::$name";
    setvar($stack, $name, "Python2::Type::Object::StdLib::$name"->new());
}

sub unescape {
    my $string = shift;

    $string =~ s/\n/\\n/g;
    $string =~ s/\t/\\t/g;

    return $string;
}

sub unsplat {
    my ($value) = @_;

    die Python2::Type::Exception->new('TypeError', 'splat(*) expects a list, got ' . $value->__type__)
        unless $value->__type__ eq 'list';

    return @$value;
}

sub py2print {
    pop(@_); # named arguments hash
    print $_->__print__ foreach(@_);
    print "\n";
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
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand +', $left->__type__, $right->__type__));
        }
    },

    '-' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left - $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand -', $left->__type__, $right->__type__));
        }
    },

    '*' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left * $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand *', $left->__type__, $right->__type__));
        }
    },

    '/' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left / $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand /', $left->__type__, $right->__type__));
        }
    },

    '//' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left / $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand //', $left->__type__, $right->__type__));
        }
    },

    '**' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left ** $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand **', $left->__type__, $right->__type__));
        }
    },

    '&' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left & $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand &', $left->__type__, $right->__type__));
        }
    },

    '|' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left | $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand |', $left->__type__, $right->__type__));
        }
    },

    '^' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left ^ $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand ^', $left->__type__, $right->__type__));
        }
    },

    '>>' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left >> $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand >>', $left->__type__, $right->__type__));
        }
    },

    '<<' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return \Python2::Type::Scalar::Num->new($left << $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand <<', $left->__type__, $right->__type__));
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
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand %%', $left->__type__, $right->__type__));
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

sub raise {
    my ($exception, $message) = @_;

    die Python2::Type::Exception->new('TypeError', 'raise expects a Exception object, got ' . $exception->__type__)
        unless $exception->__type__ eq 'exception';

    die defined $message
        ? ${ $exception->__call__(undef, $message->__tonative__) }
        : $exception;
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
            $k = ${ convert_to_python_type($k) };
            $v = ${ convert_to_python_type($v) };

            $dict->__setitem__(undef, $k, $v);
        }

        return \$dict;
    }

    # perl5 array
    if (ref($value) eq 'ARRAY') {
        return \Python2::Type::List->new(
            map { ${ convert_to_python_type($_) } } @$value
        );
    }

    if (ref($value) eq 'CODE') {
        return \Python2::Type::PerlSub->new($value);
    }

    # anything else must be a plain scalar
    return looks_like_number($value)
        ? \Python2::Type::Scalar::Num->new($value)
        : \Python2::Type::Scalar::String->new($value);
}

1;
