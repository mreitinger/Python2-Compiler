package Python2::Type::Scalar::String;
use v5.26.0;
use base qw/ Python2::Type::Scalar /;
use warnings;
use strict;

use utf8;
use MIME::Base64;
use Encode qw();

sub __str__  { return "'" . $_[0]->$* . "'"; }
sub __type__ { 'str'; }
sub __is_py_true__  { length($_[0]->$*) > 0 ? 1 : 0; }

sub split {
    pop(@_); # default named arguments hash
    my ($self, $separator, $maxsplit) = @_;

    return Python2::Type::List->new(
        Python2::Type::Scalar::String->new('')
    ) unless length $$self;

    my $joiner = $separator; # original separator - used to join in case we use maxsplit below

    if ($separator) {
        die("Expected a scalar as seperator")
            unless $separator->__type__ eq 'str';

        $separator = $separator->__tonative__;
        $separator = "\Q$separator\E";
    }
    else {
        $separator = '\s+';
    }

    my @result = split($separator, $$self);

    if ($maxsplit) {
        $maxsplit       = $maxsplit->__tonative__;
        my $result_size = scalar(@result);

        # clamp to result size
        $maxsplit = $result_size if $maxsplit > $result_size;

        my $ret = Python2::Type::List->new(
            map { Python2::Type::Scalar::String->new($_) } @result[0 .. $maxsplit-1],
            (
                ($result_size-$maxsplit > 0)
                    ? join($joiner->__tonative__, @result[$maxsplit .. $result_size-1])
                    : ()
            )
        );

        return $ret;
    }

    return Python2::Type::List->new(map { Python2::Type::Scalar::String->new($_) } @result);
}

sub rsplit {
    pop(@_); # default named arguments hash
    my ($self, $separator, $maxsplit) = @_;
    $maxsplit = $maxsplit->__tonative__ if $maxsplit;

    # mimic pythons behaviour
    $maxsplit = undef if defined $maxsplit and $maxsplit < 0;

    return Python2::Type::List->new(
        Python2::Type::Scalar::String->new( $$self )
    ) if defined $maxsplit and $maxsplit == 0;

    my $joiner = $separator; # original separator - used to join in case we use maxsplit below

    if ($separator) {
        die("Expected a scalar as seperator")
            unless $separator->__type__ eq 'str';

        $separator = $separator->__tonative__;
        $separator = "\Q$separator\E";
    }
    else {
        $separator = '\s+';
    }

    my @result = reverse split($separator, join('', split(//, $$self)));

    if ($maxsplit) {
        my $result_size = scalar(@result);

        # clamp to result size
        $maxsplit = $result_size if $maxsplit > $result_size;

        my $ret = Python2::Type::List->new(
            map { Python2::Type::Scalar::String->new($_) } reverse @result[0 .. $maxsplit-1],
            (
                ($result_size-$maxsplit > 0)
                    ? join($joiner->__tonative__, reverse @result[$maxsplit .. $result_size-1])
                    : ()
            )
        );

        return $ret;
    }

    return Python2::Type::List->new(map { Python2::Type::Scalar::String->new($_) } reverse @result);
}

sub strip {
    my $string = $_[0]->$*;

    $string =~ s/^\s*//;
    $string =~ s/\s*$//;

    return Python2::Type::Scalar::String->new($string);
}

sub lstrip {
    my $string = $_[0]->$*;

    $string =~ s/^\s*//;

    return Python2::Type::Scalar::String->new($string);
}

sub rstrip {
    my $string = $_[0]->$*;

    $string =~ s/\s*$//;

    return Python2::Type::Scalar::String->new($string);
}

sub isupper {
    my $string = $_[0]->$*;
    $string =~ s/[^a-zA-Z]//ig;

    return Python2::Type::Scalar::Bool->new(
        $string =~ m/^[A-Z]+$/ ? 1 : 0
    )
}

sub islower {
    my $string = $_[0]->$*;
    $string =~ s/[^a-zA-Z]//ig;

    return Python2::Type::Scalar::Bool->new(
        $string =~ m/^[a-z]+$/ ? 1 : 0
    )
}

sub isdigit {
    my $string = $_[0]->$*;
    $string =~ s/[^[:print:]]//ig;

    return Python2::Type::Scalar::Bool->new(
        $string =~ m/^[0-9]+$/ ? 1 : 0
    )
}


sub join {
    my ($self, $iterable) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("join() expects a string or iterable but got '%s'", $iterable->__type__))
        unless ($iterable->__type__ =~ m/^(list|str)$/);

    if ($iterable->__type__ eq 'list') {
        foreach ($iterable->ELEMENTS) {
            die Python2::Type::Exception->new('TypeError', sprintf("invalid element in iterable passed to join(): '%s'", $_->__type__))
                unless $_->__type__ eq 'str';
        }
    }

    return $iterable->__type__ eq 'list'
        ?   Python2::Type::Scalar::String->new(join($self->__tonative__, @{ $iterable->__tonative__ } ))
        :   Python2::Type::Scalar::String->new(join($self->__tonative__, split(//, $iterable->__tonative__)));
}

sub replace {
    pop(@_); # default named arguments hash
    my ($self, $old, $new, $count) = @_;

    die Python2::Type::Exception->new('TypeError',
        sprintf(
            "replace() expects old and new to be strings, got %s and %s instead",
            $old->__type__, $new->__type__)
        )
        unless $old->isa('Python2::Type::Scalar::String') and $new->isa('Python2::Type::Scalar::String');

    my $s = $self->__tonative__;
    my $o = $old->__tonative__;
    my $n = $new->__tonative__;

    if ($count) {
        die Python2::Type::Exception->new('TypeError',
            sprintf("replace() expects count to be an integer, got %s instead", $count->__type__, ))
            unless ($count->__type__ eq 'int');
        for (1.. $count->__tonative__) {
            $s =~ s/\Q$o\E/$n/;
        }
    } else {
        $s =~ s/\Q$o\E/$n/g;
    }
    return Python2::Type::Scalar::String->new($s);
}

sub splitlines {
    pop(@_); # default named arguments hash
    my ($self, $keepends) = @_;

    $keepends //= Python2::Type::Scalar::Bool->new(0);

    # TODO: to be perfectly compatible we should also support windows line endings
    # \r\n as python does, as well as some corner cases e.g. '\n\n'.splitlines()
    # but as long no issues arise this should do it

    my $regex = $keepends->__tonative__ ? '(?<=\n)' : '\n';

    return Python2::Type::List->new(
        map { Python2::Type::Scalar::String->new($_) }
        split /$regex/, $self->__tonative__
    );
}

sub capitalize {
    return Python2::Type::Scalar::String->new(ucfirst lc shift->__tonative__);
}

sub lower {
    return Python2::Type::Scalar::String->new(lc shift->__tonative__);
}

sub upper {
    return Python2::Type::Scalar::String->new(uc shift->__tonative__);
}

sub __call__ {
    my $self = shift;
    pop @_; # named arguments hash, unused

    # This is a very, very ugly hack for compatibility with ancient Zope/DTML templates.
    # Some mechanism allowed strings to be accessed as a Function Call: <dtml-var "my_string()">
    # This intercepts a __call__() invocation in case the string is already initialized - which
    # would otherwise be interpreted as a str(whatever) call.
    return $self if $$self;

    return Python2::Type::Scalar::String->new('') unless @_;

    # TODO - this attempts to convert way more than python
    return $_[0]->__type__ eq 'str'
        # __str__ for string returns "'str'" - workaround
        # so we get matching output to python2
        ?  Python2::Type::Scalar::String->new($_[0]->__tonative__)
        :  Python2::Type::Scalar::String->new($_[0]->__str__);
}

sub count {
    pop(@_); # default named arguments hash
    my ($self, $sub, $start, $end) = @_;

    $sub = $sub->__tonative__;

    $start ||= Python2::Type::Scalar::Num->new(0);
    $end ||= Python2::Type::Scalar::Num->new(length($self->__tonative__));

    die Python2::Type::Exception->new('TypeError',
        sprintf("count() expects integers as slice parameters, got %s and %s", $start->__type__, $end->__type__))
        unless ($start->__type__ eq 'int' and $end->__type__ eq 'int');

    my $offset = $end->__tonative__ - $start->__tonative__;
    my $s = substr $self->__tonative__, $start->__tonative__, $offset;
    my $c =()= $s=~ m/\Q$sub\E/g;

    return Python2::Type::Scalar::Num->new($c);
}

sub find {
    pop(@_); # default named arguments hash
    my($self, $sub, $start, $end) = @_;

    die Python2::Type::Exception->new('TypeError',
        sprintf("find() expects a string as substring, got %s", $sub->__type__))
        unless ($sub->__type__ eq 'str');

    $sub = $sub->__tonative__;
    $start ||= Python2::Type::Scalar::Num->new(0);
    $end ||= Python2::Type::Scalar::Num->new(length($self->__tonative__));

    die Python2::Type::Exception->new('TypeError',
        sprintf("find() expects integers as slice parameters, got %s and %s", $start->__type__, $end->__type__))
        unless ($start->__type__ eq 'int' and $end->__type__ eq 'int');

    my $offset = $end->__tonative__ - $start->__tonative__;
    my $s = substr $self->__tonative__, $start->__tonative__, $offset;
    my $i = index($s, $sub);
    return Python2::Type::Scalar::Num->new($i gt -1 ? $i + $start->__tonative__ : -1);
}

sub rfind {
    pop(@_); # default named arguments hash
    my($self, $sub, $start, $end) = @_;

    die Python2::Type::Exception->new('TypeError',
        sprintf("find() expects a string as substring, got %s", $sub->__type__))
        unless ($sub->__type__ eq 'str');

    $sub = $sub->__tonative__;
    $start ||= Python2::Type::Scalar::Num->new(0);
    $end ||= Python2::Type::Scalar::Num->new(length($self->__tonative__));

    die Python2::Type::Exception->new('TypeError',
        sprintf("rfind() expects integers as slice parameters, got %s and %s", $start->__type__, $end->__type__))
        unless ($start->__type__ eq 'int' and $end->__type__ eq 'int');

    my $offset = $end->__tonative__ - $start->__tonative__;
    my $s = substr $self->__tonative__, $start->__tonative__, $offset;
    my $i = rindex($s, $sub);
    return Python2::Type::Scalar::Num->new($i gt -1 ? $i + $start->__tonative__ : -1);
}

sub startswith {
    pop(@_); # default named arguments hash
    my($self, $sub, $start, $end) = @_;

    die Python2::Type::Exception->new('TypeError',
        sprintf("startswith() expects a string or tuple of strings as substring(s), got %s", $sub->__type__))
        unless ($sub->__type__ eq 'str' or $sub->__type__ eq 'tuple');

    my @subs;
    if ($sub->__type__ eq 'tuple') {
        @subs = map {
            die Python2::Type::Exception->new('TypeError', 'startswith() found invalid list element: ' . $_->__type__)
                unless ($_->__class__ eq 'Python2::Type::Scalar::String');

            $_->__tonative__;
        } @$sub;
    } else {
        @subs = ($sub->__tonative__);
    }

    $start ||= Python2::Type::Scalar::Num->new(0);
    $end ||= Python2::Type::Scalar::Num->new(length($self->__tonative__));

    die Python2::Type::Exception->new('TypeError',
        sprintf("startswith() expects integers as slice parameters, got %s and %s", $start->__type__, $end->__type__))
        unless ($start->__type__ eq 'int' and $end->__type__ eq 'int');

    my $offset = $end->__tonative__ - $start->__tonative__;
    my $s = substr $self->__tonative__, $start->__tonative__, $offset;
    for $sub (@subs) {
        my $i = index($s, $sub);
        return Python2::Type::Scalar::Bool->new(1) if $i eq 0;
    }
    return Python2::Type::Scalar::Bool->new(0);
}

sub endswith {
    pop(@_); # default named arguments hash
    my($self, $sub, $start, $end) = @_;

    die Python2::Type::Exception->new('TypeError',
        sprintf("endswith() expects a string or tuple of strings as substring(s), got %s", $sub->__type__))
        unless ($sub->__type__ eq 'str' or $sub->__type__ eq 'tuple');

    my @subs;
    if ($sub->__type__ eq 'tuple') {
        @subs = map {
            die Python2::Type::Exception->new('TypeError', 'endswith() found invalid list element: ' . $_->__type__)
                unless ($_->__class__ eq 'Python2::Type::Scalar::String');

            $_->__tonative__;
        } @$sub;
    } else {
        @subs = ($sub->__tonative__);
    }

    $start  ||= Python2::Type::Scalar::Num->new(0);
    $end    ||= Python2::Type::Scalar::Num->new(length($self->__tonative__));

    die Python2::Type::Exception->new('TypeError',
        sprintf("endswith() expects integers as slice parameters, got %s and %s", $start->__type__, $end->__type__))
        unless ($start->__type__ eq 'int' and $end->__type__ eq 'int');

    my $offset  = $end->__tonative__ - $start->__tonative__;
    my $s       = substr $self->__tonative__, $start->__tonative__, $offset;

    for $sub (@subs) {
        return Python2::Type::Scalar::Bool->new(1) if $sub eq substr($s, -length($sub));
    }

    return Python2::Type::Scalar::Bool->new(0);
}



sub __getitem__ {
    my ($self, $key) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("string slice expects an integer, got %s", $key->__type__))
        unless $key->__type__ eq 'int';

    my $position = $key->__tonative__;
    my $string   = $self->__tonative__;

    die Python2::Type::Exception->new('IndexError', 'string index out of range')
        if ($position < 0 ? $position*-1 : $position+1) > length($string);

    return Python2::Type::Scalar::String->new(
        substr($string, $position, 1)
    );
}

sub __getslice__ {
    my ($self, $start, $target) = @_;

    $start   = $start->__tonative__;
    $target  = $target->__tonative__;

    if ($target == -1) {
        $target = length($$self);
    }

    return Python2::Type::Scalar::String->new( substr($$self, $start, $target-$start) );
}

sub encode {
    pop(@_); # default named arguments hash
    my($self, $encoding, $errors) = @_;

    my $str = $self->__tonative__;
    if ($encoding =~ m/utf\-?8/) {
        warn sprintf(
            "noop encode('utf-8') used for string: '%s<truncated>'. UTF-8 is now assumed everywhere.",
            substr($str, 0, 10)
        ) unless exists $ENV{PYTHON_2_COMPILER_NO_ENCODE_WARNINGS};
    } elsif ($encoding eq 'cp1250') {
        $str = Encode::encode('cp1250', $str);
    } elsif ($encoding eq 'cp1252') {
        $str = Encode::encode('cp1252', $str);
    } elsif ($encoding eq 'base64') {
        $str = encode_base64($str);
    } else {
        die Python2::Type::Exception->new('LookupError',
            sprintf("unknown encoding: %s", $encoding));
    }
    return Python2::Type::Scalar::String->new($str);
}

sub decode {
    pop(@_); # default named arguments hash
    my($self, $encoding, $errors) = @_;

    my $str = $self->__tonative__;
    if ($encoding =~ m/utf\-?8/) {
        warn sprintf(
            "noop decode('utf-8') used for string: '%s<truncated>'. UTF-8 is now assumed everywhere.",
            substr($str, 0, 10)
        ) unless exists $ENV{PYTHON_2_COMPILER_NO_ENCODE_WARNINGS};
    } elsif ($encoding eq 'base64') {
        $str = decode_base64($str);
    } else {
        die Python2::Type::Exception->new('LookupError',
            sprintf("unknown encoding: %s", $encoding));
    }
    return Python2::Type::Scalar::String->new($str);
}

sub __gt__ {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new($self->__tonative__ gt $other->__tonative__)
        if ($other->__type__ eq 'str');

    return Python2::Type::Scalar::Bool->new(1)
        if ref($other) eq 'Python2::Type::Scalar::Num';

    return Python2::Type::Scalar::Bool->new(1)
        if $other->__type__ eq 'list';

    return Python2::Type::Scalar::Bool->new(0)
        if $other->__type__ eq 'tuple';

    return Python2::Type::Scalar::Bool->new(1)
        if $other->__type__ eq 'dict';

    return Python2::Type::Scalar::Bool->new(1)
        if ref($other) eq 'Python2::Type::Scalar::Bool';

    die Python2::Type::Exception->new('NotImplementedError', '__gt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __lt__ {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new($self->__tonative__ lt $other->__tonative__)
        if ($other->__type__ eq 'str');

    return Python2::Type::Scalar::Bool->new(0)
        if ref($other) eq 'Python2::Type::Scalar::Num';

    return Python2::Type::Scalar::Bool->new(0)
        if $other->__type__ eq 'list';

    return Python2::Type::Scalar::Bool->new(1)
        if $other->__type__ eq 'tuple';

    return Python2::Type::Scalar::Bool->new(0)
        if $other->__type__ eq 'dict';

    return Python2::Type::Scalar::Bool->new(0)
        if ref($other) eq 'Python2::Type::Scalar::Bool';

    die Python2::Type::Exception->new('NotImplementedError', '__lt__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __ge__ {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new($self->__tonative__ ge $other->__tonative__)
        if ($other->__type__ eq 'str');

    die Python2::Type::Exception->new('NotImplementedError', '__ge__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __le__ {
    my ($self, $other) = @_;

    return Python2::Type::Scalar::Bool->new($self->__tonative__ le $other->__tonative__)
        if ($other->__type__ eq 'str');

    die Python2::Type::Exception->new('NotImplementedError', '__le__ between ' . $self->__type__ . ' and ' . $other->__type__);
}

sub __contains__ {
    my ($self, $other) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("in <string> requires string as left operand, got %s", $other->__type__))
        unless ($other->__type__ eq 'str');

    return Python2::Type::Scalar::Bool->new( index($self->__tonative__, $other->__tonative__) >= 0 );
}

sub ELEMENTS {
    my ($self) = @_;

    return map { Python2::Type::Scalar::String->new( $_ ) } split(//, $self->__tonative__);
}

1;
