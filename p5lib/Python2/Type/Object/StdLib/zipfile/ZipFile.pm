package Python2::Type::Object::StdLib::zipfile::ZipFile;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

sub new {
    my ($self) = @_;
    my $object = bless({
        stack => [$Python2::builtins],
        path   => undef,
        mode   => undef,
        zip    => undef,
        opened => 0
    }, $self);

    return $object;
}

sub open {
    # https://docs.python.org/2.7/library/zipfile.html#zipfile.ZipFile.open
    pop(@_); # default named arguments hash
    my ($self, $pstack, $path, $mode, $pwd) = @_;
    $self->{path} = $path->__tonative__;
    $self->{mode} = $mode && $mode->__tonative__ || 'r';

    if (-e $self->{path} && $self->{mode} eq 'a') {
        $self->{zip} = Archive::Zip->new($self->{path});
    } else {
        $self->{zip} = Archive::Zip->new();
    }
    $self->{opened} = 1;
}

sub close {
    pop(@_); # default named arguments hash
    my ($self, $pstack) = @_;
    if ($self->{opened}) {
        if (-e $self->{path} && $self->{mode} eq 'a') {
            $self->{zip}->overwrite();
        } else {
            $self->{zip}->overwriteAs($self->{path});
        }
    }
    $self->{opened} = 0;
}

sub write {
    my ($self, $pstack, $path, $arcname) = @_;

    die Python2::Type::Exception->new('RuntimeError', 'write() requires mode "w" or "a"')
        if ($self->{mode} eq 'r');
    # arcname might be given as named argument
    $arcname = ${ $arcname->{arcname} } if (ref($arcname) eq 'HASH');

    my $member = $self->{zip}->addFile($path->{value}, $arcname->{value});
    # without zlib this is the default method python2 uses
    $member->desiredCompressionMethod(COMPRESSION_STORED);
    return Python2::Type::Scalar::None->new();
}

sub __enter__ {
    my ($self, $pstack, $path, $mode) = @_;
    return \$self;
}

sub __exit__ {
    pop(@_); # default named arguments hash
    my ($self, $pstack) = @_;
    $self->close($pstack);
}

sub __call__ {
    pop(@_); # default named arguments hash
    my ($self, $pstack, $path, $mode) = @_;
    $self->open($pstack, $path, $mode, undef, undef);
    return \$self;
}

1;
