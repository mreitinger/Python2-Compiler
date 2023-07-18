class Python2::Compiler::Service {
    use Python2::Compiler;
    use Cro::HTTP::Router;

    class Python2::Compiler::Service::Exception::FieldMissing is Exception {
        has Str $.field-name is required;
        method message { sprintf("Field '%s' missing", self.field-name); };
    }

    class Python2::Compiler::Service::Exception::FieldInvalid is Exception {
        has Str $.field-name is required;
        method message { sprintf("Field '%s' invalid", self.field-name); };
    }

    method routes {
        route {
            around -> &handler {
                handler();
                CATCH {
                    when Python2::Compiler::Service::Exception::FieldMissing {
                        note .message;
                        bad-request 'text/plain', .message;
                    }
                    when Python2::Compiler::Service::Exception::FieldInvalid {
                        note .message;
                        bad-request 'text/plain', .message;
                    }
                    when Python2::CompilationError {
                        note .message;
                        bad-request 'text/plain', .message;
                    }
                    default {
                        response.status = 500;
                        note .message;
                        content 'text/plain', .message;
                    }
                }
            }

            post -> 'compile' {
                request-body -> %data {
                    for <code type embedded> -> Str $field-name {
                        Python2::Compiler::Service::Exception::FieldMissing.new(:$field-name).throw()
                            unless %data{$field-name}:exists;
                    }

                    Python2::Compiler::Service::Exception::FieldInvalid.new(:field-name('embedded')).throw()
                        unless %data{'embedded'} ~~ /^^<[a..z0..9]>+$$/;

                    Python2::Compiler::Service::Exception::FieldInvalid.new(:field-name('type')).throw()
                        unless %data{'type'} ~~ /^^[script|expression]+$$/;

                    note sprintf("Compiling %s with id %s", %data<type>, %data<embedded>);

                    my $compiler = Python2::Compiler.new( optimize => True );
                    my $output   = %data{'type'} eq 'expression'
                        ?? $compiler.compile-expression(%data<code>, :embedded(%data<embedded>))
                        !! $compiler.compile(%data<code>, :embedded(%data<embedded>));

                    content 'text/plain', $output;
                }
            }
        }
    }
}

