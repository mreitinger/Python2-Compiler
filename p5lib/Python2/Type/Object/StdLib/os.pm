package Python2::Type::Object::StdLib::os;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use File::Find;

use Python2::Type::Object::StdLib::os::path;

sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins, {
            path => Python2::Type::Object::StdLib::os::path->new()
        }],
    }, $self);

    return $object;
}

sub remove {
    my ($self, $path) = @_;
    unlink $path or die Python2::Type::Exception->new('OSError',
        "Could not remove $path: $!");
    return Python2::Type::Scalar::None->new();
}

sub mkdir {
    my ($self, $path, $mode) = @_;
    mkdir $path or die Python2::Type::Exception->new('OSError',
        "Could not create directory $path: $!");
    return Python2::Type::Scalar::Bool->new(1);
}

sub rmdir {
    my ($self, $path, $mode) = @_;
    rmdir $path or die Python2::Type::Exception->new('OSError',
        "Could not remove directory $path: $!");
    return Python2::Type::Scalar::Bool->new(1);
}

sub walk {
    my $self = shift;
    my $named_arguments = pop;
    my $path = shift;

    die Python2::Type::Exception->new('TypeError', 'os.walk() expects a string as path, got ' . (defined $path ? $path->__type__ : 'nothing'))
        unless defined $path and $path->__type__ eq 'str';

    die Python2::Type::Exception->new('NotImplementedError', 'arguments to os.walk()')
        if keys %$named_arguments;

    # python does not care if the path does not exist so neither do we
    return Python2::Type::List->new()->__iter__()
        unless -e $path;

    my $directories = {};

    find(sub {
        return if $_ eq '.';

        $directories->{$File::Find::dir}->{path} //= $File::Find::dir;
        $directories->{$File::Find::dir}->{files} //= [];
        $directories->{$File::Find::dir}->{subdirectories} //= [];

        # File::Find sets the current working directory so a check against $_ is fine
        push(@{ $directories->{$File::Find::dir}->{files} }, $_) if -f $_;
        push(@{ $directories->{$File::Find::dir}->{subdirectories} }, $_) if -d $_;
    }, $path);

    return Python2::Type::List->new(
        map {
            Python2::Type::Tuple->new(
                Python2::Type::Scalar::String->new($_->{path}),
                Python2::Type::List->new(
                    map { Python2::Type::Scalar::String->new($_) } @{ $_->{subdirectories} }
                ),
                Python2::Type::List->new(
                    map { Python2::Type::Scalar::String->new($_) } @{ $_->{files} }
                )
            )
        } sort { $a->{path} cmp $b->{path} } values %$directories
    )->__iter__();
}

sub stat {
    my ($self, $path) = @_;

    # TODO: implement other attributes / posix.stat_result? not needed so far

    my @st = stat $path->__tonative__
        or die Python2::Type::Exception->new('OSError', 'No such file or directory: ' . $path);

    # perl stat order
    # 0 	Device number of file system
    # 1 	Inode number
    # 2 	File mode (type and permissions)
    # 3 	Number of (hard) links to the file
    # 4 	Numeric user ID of file.s owner
    # 5 	Numeric group ID of file.s owner
    # 6 	The device identifier (special files only)
    # 7 	File size, in bytes
    # 8 	Last access time since the epoch
    # 9 	Last modify time since the epoch
    # 10 	Inode change time (not creation time!) since the epoch
    # 11 	Preferred block size for file system I/O
    # 12	Actual number of blocks allocated

    # python2 stat order
    # https://docs.python.org/2.7/library/os.html#os.stat

    return Python2::Type::List->new((
        Python2::Type::Scalar::Num->new($st[2]),  # st_mode
        Python2::Type::Scalar::Num->new($st[1]),  # st_ino
        Python2::Type::Scalar::Num->new($st[0]),  # st_dev
        Python2::Type::Scalar::Num->new($st[3]),  # st_nlink
        Python2::Type::Scalar::Num->new($st[4]),  # st_uid
        Python2::Type::Scalar::Num->new($st[5]),  # st_gid
        Python2::Type::Scalar::Num->new($st[7]),  # st_size
        Python2::Type::Scalar::Num->new($st[8]),  # st_atime
        Python2::Type::Scalar::Num->new($st[9]),  # st_mtime
        Python2::Type::Scalar::Num->new($st[10]), # st_ctime
    ));
}

1;
