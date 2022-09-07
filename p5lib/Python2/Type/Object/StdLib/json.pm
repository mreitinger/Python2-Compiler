package Python2::Type::Object::StdLib::json;

use base qw/ Python2::Type::Object::StdLib::base /;

use v5.26.0;
use warnings;
use strict;

use JSON;

sub new {
    my ($self) = @_;

    my $object = bless({ stack => [$Python2::builtins] }, $self);

    return $object;
}

sub dumps {
    pop(@_); # default named arguments hash
    my ($self, $pstack, $obj, $skipkey, $ensure_ascii, $check_circular, $allow_nan,
        $cls, $indent, $separators, $encoding, $default, $sort_keys) = @_;

    my $json_str;
    if ($obj->__tonative__) {
        # TODO: implement options as needed
        # python2 uses space_after as default
        my $json = JSON->new->space_after(1);
        $json_str = $json->encode($obj->__tonative__);
    } else {
        die Python2::Type::Exception->new('TypeError',
            sprintf("object contains non-JSON serializable elements"));
    }

    return \Python2::Type::Scalar::String->new($json_str);
}

1;
