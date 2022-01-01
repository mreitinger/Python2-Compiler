use Test;
use lib './lib';

use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;

my $testcase_directory = IO::Path.new("./t/output-comparison");

unless $testcase_directory.e {
    die("Testcase directory not found, are you running tests from the wrong directory?");
}

for $testcase_directory.dir -> $testcase {
    subtest $testcase => sub {
        my $ast;
        my $generated_perl5_code;
        my $python2_output;
        my $perl5_output;
        my $parsed;

        subtest 'parser' => sub {
            lives-ok(
                sub { $parsed = Python2::Grammar.parse($testcase.slurp, actions => Python2::Actions) },
            );
        };
        $parsed or fail("parser failed for $testcase");


        subtest 'AST' => sub { lives-ok {
            $ast = $parsed.made;
        }};
        $ast or fail("AST generation failed for $testcase");


        subtest 'Python 2 execution' => sub {
            my $python2;
            lives-ok {
                $python2 = run('python2.7', $testcase, :out, :err);
                ok($python2.exitcode == 0, 'python2 exit code');
                $python2_output = $python2.out.slurp;
            }

            diag("python STDERR: { $python2.err.slurp }")
                unless $python2.exitcode == 0;
        };


        subtest 'Perl 5 code generation' => sub { lives-ok {
            my $backend = Python2::Backend::Perl5.new();
            ok($generated_perl5_code = $backend.e($ast));
        }};
        $generated_perl5_code or fail("failed to generate Perl 5 code");

        subtest 'Perl 5 execution' => sub { 
            my $perl5;
            lives-ok {
                $perl5 = run('perl', :in, :out, :err);
                $perl5.in.say($generated_perl5_code);
                $perl5.in.close;
                ok($perl5.exitcode == 0, 'perl exit code');
                $perl5_output = $perl5.out.slurp;
            }

            diag("perl 5 STDERR: { $perl5.err.slurp }")
                unless $perl5.exitcode == 0;
        };

        subtest 'Output comparison' => sub {
            is $perl5_output, $python2_output, 'output matches';
        };
    };
}

done-testing();
