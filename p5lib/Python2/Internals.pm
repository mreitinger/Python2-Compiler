package Python2::Internals;
use v5.26.0;
use warnings;
use strict;
use List::Util::XS; # ensure we use the ::XS version
use Text::Sprintf::Named qw(named_sprintf);
use Data::Dumper;

use Scalar::Util qw/ looks_like_number blessed isdual /;
use Carp qw/ confess /;
use Module::Load;

use Python2::Internals::Ext;

use constant {
    PARENT  => 0,
    ITEMS   => 1,
};

# set a variable on our stack, only used for internals
# everything else must assign to the ref returned by getvar
sub setvar {
    my ($stack, $name, $value) = @_;

    $stack->set($name, $value);
}

# delete a variable on our stack
sub delvar {
    my ($stack, $name) = @_;

    if ($stack->has($name)) { warn 'has' . $stack->has($name); }

    $stack->has($name)
        ? $stack->delete($name)
        : die Python2::Type::Exception->new('NameError', "name '$name' not defined");
}

# return a reference to a variable name on our stack
sub getvar : lvalue {
    my ($stack, $recurse, $name, $gracefully) = @_;

    # if recursion is disabled (for variable assignment) don't travel upwards on the stack
    return $stack->get($name, $gracefully)
        unless $recurse;

    # recursion enabled - look upwards to find the variable
    my $call_frame = $stack;

    until ($call_frame->has($name) or not defined $call_frame->parent) {
        $call_frame = $call_frame->parent;
    }

    $call_frame->has($name)
        ? $call_frame->get($name)
        : $stack->get($name);
}

sub import_module {
    my ($stack, $import_definition) = @_;

    foreach my $module (@$import_definition) {
        my $name = $module->{name};
        my $name_as = $module->{name_as};

        $name =~ s/\./::/g;

        eval {
            load "Python2::Type::Object::StdLib::$name";
            1;
        } or do {
            die Python2::Type::Exception->new('ImportError', "Failed to load module '$name': $@");
        };

        # used when only importing names with from foo import bar
        if (defined $module->{functions}) {
            my $object = "Python2::Type::Object::StdLib::$name"->new();

            foreach my $function_name (@{ $module->{functions} }) {
                if ($object->can($function_name)) {
                    setvar($stack, $function_name,
                        Python2::Type::PythonMethod->new($object->can($function_name), $object)
                    );

                    return;
                }

                if (
                    $object->can('__hasattr__') and
                    $object->__hasattr__(Python2::Type::Scalar::String->new($function_name))->__tonative__
                ) {
                    setvar($stack, $function_name,
                        $object->__getattr__(Python2::Type::Scalar::String->new($function_name))
                    );

                    return;
                }

                die Python2::Type::Exception->new('ImportError', "Module '$name' has no attribute '$function_name'");
            }
        }

        # regular 'import foo'
        else {
            setvar($stack, $name_as, "Python2::Type::Object::StdLib::$name"->new());
        }
    }
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
    my @values = @_;

    print join(' ', map { $_->__print__ } @values);
    print "\n";
}


# TODO all of those should use the magic methods like python does.
# TODO This way we could skip a lot of the type checks
my $arithmetic_operations = {
    '+' => sub {
        my ($left, $right) = @_;

        return $left->__add__($right) if $left->can('__add__');

        if ($left->isa('Python2::Type::Scalar::Num') and ($right->isa('Python2::Type::Scalar::Num'))) {
            return Python2::Type::Scalar::Num->new($left->__tonative__ + $right->__tonative__);
        }
        elsif (($left->__type__ eq 'list') and ($right->__type__ eq 'list')) {
            return Python2::Type::List->new($left->ELEMENTS, $right->ELEMENTS);
        }

        # this, unlike python, allows things like "print 1 + 'a'"
        # avoiding this by doing harsher checks against perl's internals hinders
        # interoperability with other perl objects
        elsif ((ref($left) =~ m/^Python2::Type::Scalar/) and (ref($right) =~ m/^Python2::Type::Scalar/)) {
            return Python2::Type::Scalar::String->new($left->__tonative__ . $right->__tonative__);
        }
        else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand +', $left->__type__, $right->__type__));
        }
    },

    '-' => sub {
        my ($left, $right) = @_;

        return $left->__sub__($right) if $left->can('__add__');

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return Python2::Type::Scalar::Num->new($left - $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand -', $left->__type__, $right->__type__));
        }
    },

    '*' => sub {
        my ($left, $right) = @_;

        if ($left->isa('Python2::Type::Scalar::Num') and $right->isa('Python2::Type::Scalar::Num')) {
            return Python2::Type::Scalar::Num->new($left->__tonative__ * $right->__tonative__);
        } elsif ($left->isa('Python2::Type::Scalar::String') and $right->isa('Python2::Type::Scalar::Num')) {
            return Python2::Type::Scalar::String->new($left->__tonative__ x int($right->__tonative__));
        } elsif (($left->__type__ eq 'list') and ($right->__type__ eq 'int')) {
            my $count = $right->__tonative__;
            $count = 0 if $count < 0;
            my $target = Python2::Type::List->new();

            for (1 .. $right) {
                $target->append($_) foreach $left->ELEMENTS;
            }

            return $target;
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand *', $left->__type__, $right->__type__));
        }
    },

    '/' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            if ($left =~ m/^\d+$/ and $right =~ m/^\d+$/) {
                # pure integer division always returns integer
                return Python2::Type::Scalar::Num->new(int($left / $right));
            }
            else {
                return Python2::Type::Scalar::Num->new($left / $right);
            }
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand /', $left->__type__, $right->__type__));
        }
    },

    '//' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return Python2::Type::Scalar::Num->new($left / $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand //', $left->__type__, $right->__type__));
        }
    },

    '**' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return Python2::Type::Scalar::Num->new($left ** $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand **', $left->__type__, $right->__type__));
        }
    },

    '&' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return Python2::Type::Scalar::Num->new($left & $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand &', $left->__type__, $right->__type__));
        }
    },

    '|' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return Python2::Type::Scalar::Num->new($left | $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand |', $left->__type__, $right->__type__));
        }
    },

    '^' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return Python2::Type::Scalar::Num->new($left ^ $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand ^', $left->__type__, $right->__type__));
        }
    },

    '>>' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return Python2::Type::Scalar::Num->new($left >> $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand >>', $left->__type__, $right->__type__));
        }
    },

    '<<' => sub {
        my ($left, $right) = @_;

        $left  = $left->__tonative__;
        $right = $right->__tonative__;

        if (looks_like_number($left) and looks_like_number($right)) {
            return Python2::Type::Scalar::Num->new($left << $right);
        } else {
            die Python2::Type::Exception->new('NotImplementedError', sprintf('unsupported operand type(s) for %s and %s with operand <<', $left->__type__, $right->__type__));
        }
    },

    '%' => sub {
        my ($left, $right) = @_;

        if (looks_like_number($left->__tonative__) and looks_like_number($right->__tonative__)) {
            return Python2::Type::Scalar::Num->new($left->__tonative__ % $right->__tonative__);
        }

        # this, unlike python, allows things like "print 1 + 'a'"
        # avoiding this by doing harsher checks against perl's internals hinders
        # interoperability with other perl objects
        elsif (!looks_like_number($left->__tonative__) or !looks_like_number($right->__tonative__)) {
            return Python2::Type::Scalar::String->new(
                $right->isa('Python2::Type::Dict')
                    ? named_sprintf(
                        $left->__tonative__,
                        $right->__tonative_strings__,
                    )
                    : sprintf(
                        $left->__tonative__,
                        $right->isa('Python2::Type::List')
                            ? map { $_->__print__ } @$right
                            : $right->__print__
                    )
            );
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
        ? $exception->__call__($message->__tonative__)
        : $exception;
}

sub getopt {
    my ($stack, $function_name, $argument_definition, @arguments) = @_;

    # named arguments get passed as a hashref at the last position. be convention the hashref is
    # always present so it's safe to pop() it here. this ensures the hashref does not conflict
    # with any other arguments.
    my $named_arguments = pop(@arguments);

    confess('Python2::NamedArgumentsHash missing in call to getopt()')
        unless ref($named_arguments) eq 'Python2::NamedArgumentsHash';

    foreach my $argument (@$argument_definition) {
        my $name    = $argument->[0]; # name of this argument.
        my $default = $argument->[1]; # default value of this argument. might be undef.
        my $splat   = $argument->[2]; # 'splat' was specified (*args), grab all remaining args

        # splat does not care if any arguments are there, it just returns an empty tuple if
        # no more arguments remain
        if ($splat == 1) {
            setvar($stack, $name, Python2::Type::Tuple->new(@arguments));
            last;
        }
        elsif ($splat == 2) {
            setvar($stack, $name, Python2::Type::Dict->new(%$named_arguments));
            last;
        }

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
            setvar($stack, $name, $named_arguments->{$name});
            delete $named_arguments->{$name};
            next;
        }

        # we got nothing, use the default.
        setvar($stack, $name, $default);
    }
}

# converts any data structure to our 'native' "reference to a Python2::Type::* object" representation
sub convert_to_python_type {
    my ($value) = @_;

    # undef
    return Python2::Type::Scalar::None->new() unless defined $value;

    # if it's already a native type just return it
    if (blessed($value) and $value->isa('Python2::Type')) {
        return $value;
    }

    # some foreign perl object - wrap it in our PerlObject wrapper so it conforms to our
    # calling conventions
    if (blessed($value)) {
        return Python2::Type::PerlObject->new_from_object($value)
    }

    # perl5 hashref
    if (ref($value) eq 'HASH') {
        return Python2::Type::PerlHash->new($value);
    }

    # perl5 array
    if (ref($value) eq 'ARRAY') {
        return Python2::Type::PerlArray->new($value);
    }

    if (ref($value) eq 'CODE') {
        return Python2::Type::PerlSub->new($value);
    }

    # A dualvar wich explicit numeric representation as returned by, for example, by
    # `exists $hashref->{key} which returnes` an empty string with 0 as numeric
    # representation. Without this the empty string would cause comparisons such as
    # empty_string > 0 to return True instead of False (0 > 0).
    #
    # This matches Inline::Python so existing code can works as-is.
    if (isdual($value)) {
        return Python2::Type::Scalar::Num->new($value + 0);
    }

    # Check against the SV type of the Scalar to exactly match the behaviour of Inline::Python.
    # See perlguts/SvPOKp(SV*) and the Inline::Python source for details.
    return Python2::Internals::Ext::is_string($value)
        ? Python2::Type::Scalar::String->new($value)
        : Python2::Type::Scalar::Num->new($value);
}

1;
