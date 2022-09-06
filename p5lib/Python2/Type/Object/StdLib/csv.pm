package Python2::Type::Object::StdLib::csv;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use Text::CSV_XS qw( csv );
use Scalar::Util qw/ looks_like_number /;

sub new {
    my ($self) = @_;

    my $object = bless({
        stack => [$Python2::builtins],
    }, $self);

    return $object;
}

sub reader {
    my ($self, $pstack, $csvfile, $named_args) = @_;

    # TODO: implement other options? not needed so far
    my $delimiter = $named_args->{delimiter} ? ${ $named_args->{delimiter} } : ',';

    my $input = csv(in => $csvfile->[0], sep_char => $delimiter);
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
