package Python2::Type::Object::StdLib::os;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;


sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins],
    }, $self);

    return $object;
}

sub stat {
    my ($self, $pstack, $path) = @_;

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

    return \Python2::Type::List->new((
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
