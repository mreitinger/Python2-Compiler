package Python2::Type::Object::StdLib::csv;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Text::CSV_XS qw/ csv /;
use Scalar::Util qw/ looks_like_number /;

sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins],
    }, $self);

    return $object;
}

sub reader {
    my ($self, $csvfile, $named_args) = @_;

    # TODO: implement other options? not needed so far
    my $delimiter = $named_args->{delimiter} ? ${ $named_args->{delimiter} } : ',';

    die Python2::Type::Exception->("TypeError", $csvfile->__type__ . " does not implement read()")
        unless $csvfile->can("read");

    my $in = ${ $csvfile->read(undef) };

    die Python2::Type::Exception->("TypeError", $csvfile->__type__ . ".read() expected string, got " . $in->__type__)
        unless ref($in) =~ m/^Python2::Type::Scalar/;

    my $input = csv(in => \$in->__tonative__, sep_char => $delimiter);
    my @input_pyobj = map {
        Python2::Type::List->new(map {
            looks_like_number($_)
            ? Python2::Type::Scalar::Num->new($_)
            : Python2::Type::Scalar::String->new($_);
        } @$_)
    } @$input;

    # simply return a list which is good enough
    # as long we don't have to deal with huge files
    return \Python2::Type::List->new(@input_pyobj);
}

1;
