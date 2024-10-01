package Python2::Type::Object::StdLib::os::path;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use File::Spec;
use File::Basename ();
use List::MoreUtils;


sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins],
    }, $self);

    return $object;
}

sub exists {
    my ($self, $path) = @_;
    return Python2::Type::Scalar::Bool->new(-e $path)
}

sub isfile {
    my ($self, $path) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("isfile() expects a string but got '%s'", defined $path ? $path->__type__ : 'nothing'))
        unless defined $path and $path->__type__ eq 'str';

    return Python2::Type::Scalar::Bool->new(-f $path);
}

sub basename {
    pop; # unused named arguments hash
    my ($self, $path) = @_;

    die Python2::Type::Exception->new('TypeError', sprintf("basename() expects a string but got '%s'", defined $path ? $path->__type__ : 'nothing'))
        unless defined $path and $path->__type__ eq 'str';

    return Python2::Type::Scalar::String->new('') if $path =~ m!/$!;
    return Python2::Type::Scalar::String->new(File::Basename::basename($path));
}

sub getsize {
    my $self = shift;
    pop; # unused named arguments hash
    my $path = shift;

    die Python2::Type::Exception->new('TypeError', sprintf("getsize() expects a string as path but got '%s'", defined $path ? $path->__type__ : 'nothing'))
        unless defined $path and $path->__type__ eq 'str';

    die Python2::Type::Exception->new('OSError', sprintf("No such file or directory: %s", $path->__tonative__))
        unless -e $path;

    return Python2::Type::Scalar::Num->new(-s $path);
}

sub join {
    my $self = shift;
    pop; # unused named arguments hash

    die Python2::Type::Exception->new('TypeError', sprintf("join() expects at least one argument as path but got nothing"))
        unless scalar @_;

    foreach (@_) {
        die Python2::Type::Exception->new('TypeError', sprintf("join() expects at list of strings path but found '%s' in argument list", $_->__type__))
            unless $_->__type__ eq 'str';
    }


    # match pythons behaviour of skipping everything before the last path separator int he list
    my $last_path_separator = List::MoreUtils::last_index(sub { $_ eq '/' }, @_);

    return Python2::Type::Scalar::String->new(
        File::Spec->catfile(

            @_[
                ($last_path_separator == -1 ? 0 : $last_path_separator)
                ..
                scalar @_ - 1
            ]
        )
    );
}

sub split {
    my $self = shift;
    pop; # unused named arguments hash

    my $path = shift;

    die Python2::Type::Exception->new('TypeError', sprintf("split() expects a string as path but got '%s'", defined $path ? $path->__type__ : 'nothing'))
        unless defined $path and $path->__type__ eq 'str';

    my @path = File::Spec->splitpath($path);
    shift @path; # we don't care about Volume

    # remove trailing slash to match python
    $path[0] =~ s!/+$!! unless $path[0] =~ m!^/+$!;

    return Python2::Type::Tuple->new(
        map { Python2::Type::Scalar::String->new($_) } @path
    );
}

1;
