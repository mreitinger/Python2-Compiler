use Test;
use lib './lib';

use Python2::Compiler;

subtest "embedding" => sub {
    my Str $input = q:to/END/;
    print a
    print b
    print c
    END

    my $compiler = Python2::Compiler.new(
        embedded => 'quux',
    );

    my $generated_perl5_code = $compiler.compile($input);

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();
        $p5->__run__({ a => 'b', b => ['1', '2', '3'], c => { 4 => 5 } });
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

    is $perl5_output, "b\n[1, 2, 3]\n\{4: 5\}\n", 'output matches';

};

done-testing();
