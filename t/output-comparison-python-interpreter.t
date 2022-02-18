use Test;
use lib './lib';

use Python2::Grammar;
use Python2::Actions;
use Python2::Optimizer;
use Python2::Backend::Perl5;

my $testcase_directory = IO::Path.new("./t/output-comparison-python-interpreter");

unless $testcase_directory.e {
    die("Testcase directory not found, are you running tests from the wrong directory?");
}

for $testcase_directory.dir -> $testcase {
    subtest "Test for $testcase" => sub {
        my $ast = Nil;
        my $generated_perl5_code = Nil;
        my $python2_output = Nil;
        my $perl5_output = Nil;
        my $parsed = Nil;

        subtest "Parser for $testcase" => sub {
            $parsed = Python2::Grammar.parse($testcase.slurp, actions => Python2::Actions);
        };
        $parsed or flunk("Parser failed for $testcase");


        subtest "AST for $testcase" => sub {
            $ast = $parsed.made;
        };
        $ast or flunk("AST generation failed for $testcase");


        subtest "Python 2 execution for $testcase" => sub {
            my $python2 = run('python2.7', $testcase, :out, :err);
            ok($python2.exitcode == 0, 'python2 exit code');
            $python2_output = $python2.out.slurp;

            diag("python STDERR: { $python2.err.slurp }")
                unless $python2.exitcode == 0;
        };
        $python2_output !~~ Nil or flunk("Python 2 execution failed for $testcase");


        subtest "Perl 5 code generation for $testcase" => sub {
            my $backend = Python2::Backend::Perl5.new();
            ok($generated_perl5_code = $backend.e($ast));
        };
        $generated_perl5_code or flunk("Failed to generate Perl 5 code for $testcase");

        subtest "Perl 5 execution $testcase" => sub {
            my $perl5;
            lives-ok {
                $perl5 = run('perl', :in, :out, :err);
                $perl5.in.say($generated_perl5_code);
                $perl5.in.close;
                $perl5_output = $perl5.out.slurp;
            }

            diag("perl 5 STDERR: { $perl5.err.slurp } CODE:\n\n---\n$generated_perl5_code\n---\n")
                unless $perl5.exitcode == 0;
        };
        $perl5_output !~~ Nil or flunk("Failed Perl 5 execution for $testcase");


        subtest 'Output comparison ' ~ $testcase => sub {
            is $perl5_output, $python2_output, 'output matches';
        };
    };
}

done-testing();
