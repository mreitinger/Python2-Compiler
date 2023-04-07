# Handles support for Inline::Python's perl.ModuleName.SubModuleName.Method(arguments) syntax.

package Python2::PerlWrapper;

use base qw/ Python2::Type /;

use v5.26.0;
use warnings;
use strict;

use Module::Load;

sub new {
    my ($self, @arguments) = @_;

    # perl.Module.new(args) was called. Due to the $module->can('method') shortcut we generate
    # we end up here instead of __call__(). Check if we are instanciated already and, if so,
    # re-dispatch to __call__.
    if (ref $self) {
        push(@{ $self->{path} }, 'new');
        return $self->__call__(undef, @arguments);
    }

    my $object = bless({
        path => [@arguments],
    }, $self);

    return $object;
}

sub __getattr__ {
    my ($self, $attr) = @_;

    return \Python2::PerlWrapper->new(@{ $self->{path} }, $attr->__tonative__);
}

sub __call__ {
    my $self = shift;
    shift; # get rid of the python 'self'

    # Arguments passed to the method
    my @argument_list = @_;

    # last argument is the hashref with named arguments
    my $named_arguments = pop(@argument_list);

    # the last entry in the path is the method the user requested. extract it.
    my $requested_method = pop @{ $self->{path} };

    # remaining path is the Module/Package name
    my $module_name = join("::", @{ $self->{path} });

    # attempt to load the perl module and translate possible errors to ImportError exceptions
    eval {
        load $module_name;
    }
    or do {
        die Python2::Type::Exception->new('ImportError', $@) if $@;
    };

    # we don't support named arguments but still expect the empty hash - just here to catch bugs
    die Python2::Type::Exception->new('ValueError', "expected named arguments hash when calling perl5 method $requested_method on $module_name")
        unless ref($named_arguments) eq 'Python2::NamedArgumentsHash';

    # regular perl modules don't have a distinction between regular and named arguments
    die Python2::Type::Exception->new('NotImplementedError', "named arguments not supported when calling perl5 method $requested_method on $module_name")
        if keys %$named_arguments;

    # convert all 'Python' objects to native representations
    foreach my $argument (@argument_list) {
        $argument = $argument->__tonative__;
    }

    foreach my $argument (keys %$named_arguments) {
        $named_arguments->{$argument} = ${$named_arguments->{$argument}}->__tonative__;
    }

    my @retval;

    die Python2::Type::Exception->new('AttributeError', "Perl 5 Module $module_name has no method $requested_method")
        unless $module_name->can($requested_method);

    eval {
        @retval = $module_name->can($requested_method)->(@argument_list);
    };

    if ($@) {
        die Python2::Type::Exception->new('Exception', $@);
    }

    if (scalar(@retval) > 1) {
        return Python2::Internals::convert_to_python_type([@retval]);
    }
    else {
        return Python2::Internals::convert_to_python_type($retval[0]);
    }
}

sub __type__ { 'PerlWrapper' }

1;