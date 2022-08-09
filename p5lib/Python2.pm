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
            'len'       => Python2::Builtin::Len->new(),

            'None'      => Python2::Type::Scalar::None->new(),
            'True'      => Python2::Type::Scalar::Bool->new(1),
            'False'     => Python2::Type::Scalar::Bool->new(0),
            'Exception' => Python2::Builtin::Exception->new(), # Exception gets a message passed so
                                                               # it is implemented as a function
        }
    ]
];

1;
