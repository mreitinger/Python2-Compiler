package Python2::Type::Scalar::String;
use v5.26.0;
use base qw/ Python2::Type::Scalar /;
use warnings;
use strict;

sub __str__ { return "'" . shift->{value} . "'"; }

sub split {
    pop(@_); # default named arguments hash
    my ($self, $separator, $maxsplit) = @_;

    my $joiner = $separator; # original separator - used to join in case we use maxsplit below

    if ($separator) {
        # TODO this allowes a bit more than python
        die("Expected a scalar as seperator")
            unless $separator->__type__ eq 'scalar';

        $separator = $separator->__tonative__;
        $separator = "\Q$separator\E";
    }
    else {
        $separator = '\s+';
    }

    my @result = split($separator, $self->{value});

    if ($maxsplit) {
        $maxsplit       = $maxsplit->__tonative__;
        my $result_size = scalar(@result);

        # clamp to result size
        $maxsplit = $result_size if $maxsplit > $result_size;

        my $ret = \Python2::Type::List->new(
            map { Python2::Type::Scalar::String->new($_) } @result[0 .. $maxsplit-1],
            (
                ($result_size-$maxsplit > 0)
                    ? join($joiner->__tonative__, @result[$maxsplit .. $result_size-1])
                    : ()
            )
        );

        return $ret;
    }

    return \Python2::Type::List->new(map { Python2::Type::Scalar::String->new($_) } @result);
}

1;
