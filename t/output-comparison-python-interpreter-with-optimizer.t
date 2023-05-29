use Test;
use lib './lib';

use Python2::Grammar;
use Python2::Actions;
use Python2::Optimizer;
use Python2::Backend::Perl5;
use Python2::Compiler;

my $testcase_directory = IO::Path.new("./t/output-comparison-python-interpreter");

unless $testcase_directory.e {
    die("Testcase directory not found, are you running tests from the wrong directory?");
}

%*ENV<PYTHONIOENCODING> = 'utf8';
%*ENV<PYTHONPATH> = './t/pylib';

for $testcase_directory.dir -> $testcase {
    my $compiler-optimized   = Python2::Compiler.new(:optimize(True));
    my $compiler-unoptimized = Python2::Compiler.new(:optimize(False));

    # really ugly hack: empty line test has nothing to be optimized and would fail the 'optimized code is smaller' test
    next if ($testcase ~~ m/\/empty\-line\.py$/);

    subtest "Test for $testcase" => sub {
        my $ast-unoptimized;
        my $ast-optimized;
        my $parsed-unoptimized;
        my $parsed-optimized;

        my $optimized_perl5_code;
        my $python2_output;
        my $perl5_output;

        subtest "Parser for $testcase" => sub {
            $parsed-optimized = $compiler-optimized.parser.parse($testcase.slurp, actions => Python2::Actions::Complete);
            $parsed-unoptimized = $compiler-unoptimized.parser.parse($testcase.slurp, actions => Python2::Actions::Complete);
        };
        $parsed-optimized or flunk("Parser-optimized failed for $testcase");
        $parsed-unoptimized or flunk("Parser-optimized failed for $testcase");


        subtest "AST for $testcase" => sub {
            $ast-optimized = $parsed-optimized.made;
            $ast-unoptimized = $parsed-unoptimized.made;
        };
        $ast-optimized or flunk("AST-optimized generation failed for $testcase");
        $ast-unoptimized or flunk("AST-unoptimized generation failed for $testcase");


        subtest "Python 2 execution for $testcase" => sub {
            my $python2 = run('python2.7', $testcase, :out, :err);
            ok($python2.exitcode == 0, 'python2 exit code');
            $python2_output = $python2.out.slurp;

            diag("python STDERR: { $python2.err.slurp }")
                unless $python2.exitcode == 0;
        };
        $python2_output !~~ Nil or flunk("Python 2 execution failed for $testcase");


        subtest "Perl 5 code generation for $testcase" => sub {
            my $unoptimized_perl5_code  = $compiler-unoptimized.backend.e($ast-unoptimized);

            $compiler-optimized.optimizer.t($ast-optimized);

            $optimized_perl5_code       = $compiler-optimized.backend.e($ast-optimized);

            #cmp-ok(
            #    $unoptimized_perl5_code.chars, '>', $optimized_perl5_code.chars,
            #    'resulting optimized code is smaller than unoptimized'
            #);
        };
        $optimized_perl5_code or flunk("Failed to generate Perl 5 code for $testcase");

        subtest "Perl 5 execution $testcase" => sub {
            my $perl5;
            lives-ok {
                $perl5 = run('perl', :in, :out, :err);
                $perl5.in.say($optimized_perl5_code);
                $perl5.in.close;
                $perl5_output = $perl5.out.slurp;
            }

            diag("perl 5 STDERR: { $perl5.err.slurp } CODE:\n\n---\n$optimized_perl5_code\n---\n")
                unless $perl5.exitcode == 0;
        };
        $perl5_output !~~ Nil or flunk("Failed Perl 5 execution for $testcase");


        subtest 'Output comparison ' ~ $testcase => sub {
            is $perl5_output, $python2_output, 'output matches';
        };
    };
}

done-testing();
