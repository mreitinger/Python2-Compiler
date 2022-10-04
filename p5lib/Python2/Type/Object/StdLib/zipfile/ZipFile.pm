package Python2::Type::Object::StdLib::zipfile::ZipFile;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

sub new {
    my ($self) = @_;

    my $object = bless([
        Python2::Stack->new($Python2::builtins),
        {
            path   => undef,
            mode   => undef,
            zip    => undef,
            opened => 0
        }
    ], $self);

    return $object;
}

# https://docs.python.org/2.7/library/zipfile.html#zipfile.ZipFile.open
sub open {
    pop(@_); # default named arguments hash

    my ($self, $path, $mode, $pwd) = @_;
    $self->[1]->{path} = $path->__tonative__;
    $self->[1]->{mode} = $mode && $mode->__tonative__ || 'r';

    if (-e $self->[1]->{path} && $self->[1]->{mode} eq 'a') {
        $self->[1]->{zip} = Archive::Zip->new($self->[1]->{path});
    } else {
        $self->[1]->{zip} = Archive::Zip->new();
    }
    $self->[1]->{opened} = 1;
}

sub close {
    pop(@_); # default named arguments hash
    my ($self, $pstack) = @_;
    if ($self->[1]->{opened}) {
        if (-e $self->[1]->{path} && $self->[1]->{mode} eq 'a') {
            $self->[1]->{zip}->overwrite();
        } else {
            $self->[1]->{zip}->overwriteAs($self->[1]->{path});
        }
    }
    $self->[1]->{opened} = 0;
}

sub write {
    my ($self, $path, $arcname) = @_;

    die Python2::Type::Exception->new('RuntimeError', 'write() requires mode "w" or "a"')
        if ($self->[1]->{mode} eq 'r');

    # arcname might be given as named argument
    $arcname = ${ $arcname->{arcname} } if (ref($arcname) eq 'HASH');

    my $member = $self->[1]->{zip}->addFile($path->__tonative__, $arcname->__tonative__);

    # without zlib this is the default method python2 uses
    $member->desiredCompressionMethod(COMPRESSION_STORED);
    return Python2::Type::Scalar::None->new();
}

sub __enter__ {
    my ($self, $path, $mode) = @_;
    return \$self;
}

sub __exit__ {
    pop(@_); # default named arguments hash
    my ($self, $pstack) = @_;
    $self->close($pstack);
}

sub __call__ {
    pop(@_); # default named arguments hash

    # we care about the ZipFile instance not zipfile (naming is hard) hence the $dummy
    my ($self, $dummy, $path, $mode) = @_;
    $self->open($path, $mode, undef, undef);
    return \$self;
}

1;
