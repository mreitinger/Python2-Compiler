use Test;
use lib './lib';

use Python2::Compiler;

%*ENV<PERL5LIB> = %*ENV<PERL5LIB> ~ ':./p5lib';

subtest "compile expression" => sub {
    my Str $input = q:to/END/;
    1+1
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile-expression($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        print ${ Python2::Type::CodeObject::quux->new()->__call__ }->__tonative__;
    END

    my $perl5;
    my $perl5_output;
    lives-ok {
        $perl5 = run('perl', :in, :out, :err);
        $perl5.in.say($generated_perl5_code);
        $perl5.in.close;
        $perl5_output = $perl5.out.slurp;
    }

    diag("perl 5 STDERR: { $perl5.err.slurp } CODE:\n\n---\n$generated_perl5_code\n---\n")
        unless $perl5.exitcode == 0;

    is $perl5_output, "2", 'output matches';
};

done-testing();
