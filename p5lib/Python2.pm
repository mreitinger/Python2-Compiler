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
use Python2::Stack::Frame;

use Python2::PerlWrapper;

use Python2::Type::List;
use Python2::Type::Set;
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
use Python2::Type::PerlHash;
use Python2::Type::PerlArray;

# builtins is used as our top level stack so it must look like one
our $builtins = Python2::Stack->new(undef, Python2::Stack::Frame->new({
    'sorted'        => Python2::Builtin::Sorted->new(),
    'int'           => Python2::Builtin::Int->new(),
    'float'         => Python2::Builtin::Float->new(),
    'hasattr'       => Python2::Builtin::Hasattr->new(),
    'map'           => Python2::Builtin::Map->new(),
    'range'         => Python2::Builtin::Range->new(),
    'open'          => Python2::Builtin::Open->new(),
    'iter'          => Python2::Builtin::Iter->new(),
    'chr'           => Python2::Builtin::Chr->new(),
    'next'          => Python2::Builtin::Next->new(),
    'enumerate'     => Python2::Builtin::Enumerate->new(),
    'filter'        => Python2::Builtin::Filter->new(),
    'sum'           => Python2::Builtin::Sum->new(),
    'round'         => Python2::Builtin::Round->new(),
    'len'           => Python2::Builtin::Len->new(),
    'set'           => Python2::Builtin::Set->new(),
    'dumpstack'     => Python2::Builtin::Dumpstack->new(),
    'any'           => Python2::Builtin::Any->new(),
    'isinstance'    => Python2::Builtin::Isinstance->new(),
    'type'          => Python2::Builtin::Type->new(),
    'dump'          => Python2::Builtin::Dump->new(),
    'die'           => Python2::Builtin::Die->new(),
    'warn'          => Python2::Builtin::Warn->new(),
    'ord'           => Python2::Builtin::Ord->new(),

    'list'          => Python2::Type::List->new(),
    'dict'          => Python2::Type::Dict->new(),
    'str'           => Python2::Type::Scalar::String->new(),

    # Somewhat ugly: we don't have a separate unicode string and this allowes more than
    # Python does. Currently this is only used for isinstance() checks - good enough here.
    'basestring'    => Python2::Type::Scalar::String->new(),

    'perl'          => Python2::PerlWrapper->new(),

    'None'          => Python2::Type::Scalar::None->new(),
    'True'          => Python2::Type::Scalar::Bool->new(1),
    'False'         => Python2::Type::Scalar::Bool->new(0),

    # Exceptions gets a message passed so they get implemented as a function - this is not
    # 100% correct but should cover our use case
    'Exception'             => Python2::Type::Exception->new('Exception'),
    'StandardError'         => Python2::Type::Exception->new('StandardError'),
    'ArithmeticError'       => Python2::Type::Exception->new('ArithmeticError'),
    'LookupError'           => Python2::Type::Exception->new('LookupError'),
    'AssertionError'        => Python2::Type::Exception->new('AssertionError'),
    'AttributeError'        => Python2::Type::Exception->new('AttributeError'),
    'EOFError'              => Python2::Type::Exception->new('EOFError'),
    'EnvironmentError'      => Python2::Type::Exception->new('EnvironmentError'),
    'FloatingPointError'    => Python2::Type::Exception->new('FloatingPointError'),
    'IOError'               => Python2::Type::Exception->new('IOError'),
    'ImportError'           => Python2::Type::Exception->new('ImportError'),
    'IndexError'            => Python2::Type::Exception->new('IndexError'),
    'KeyError'              => Python2::Type::Exception->new('KeyError'),
    'KeyboardInterrupt'     => Python2::Type::Exception->new('KeyboardInterrupt'),
    'MemoryError'           => Python2::Type::Exception->new('MemoryError'),
    'NameError'             => Python2::Type::Exception->new('NameError'),
    'NotImplementedError'   => Python2::Type::Exception->new('NotImplementedError'),
    'OSError'               => Python2::Type::Exception->new('OSError'),
    'OverflowError'         => Python2::Type::Exception->new('OverflowError'),
    'ReferenceError'        => Python2::Type::Exception->new('ReferenceError'),
    'RuntimeError'          => Python2::Type::Exception->new('RuntimeError'),
    'StopIteration'         => Python2::Type::Exception->new('StopIteration'),
    'SyntaxError'           => Python2::Type::Exception->new('SyntaxError'),
    'SystemError'           => Python2::Type::Exception->new('SystemError'),
    'SystemExit'            => Python2::Type::Exception->new('SystemExit'),
    'TypeError'             => Python2::Type::Exception->new('TypeError'),
    'ValueError'            => Python2::Type::Exception->new('ValueError'),
    'ZeroDivisionError'     => Python2::Type::Exception->new('ZeroDivisionError'),
}));

1;
