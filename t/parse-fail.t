use Test;
use lib './lib';

use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;

my $testcase_directory = IO::Path.new("./t/parse-fail");

unless $testcase_directory.e {
    die("Testcase directory not found, are you running tests from the wrong directory?");
}

for $testcase_directory.dir -> $testcase {
    subtest $testcase => sub {
        my $parsed;

        subtest 'parser' => sub {
            lives-ok(
                sub { $parsed = Python2::Grammar.parse($testcase.slurp, actions => Python2::Actions); },
            );
            ok !$parsed.defined, 'parser refused invalid code';
        };


        subtest 'Python 2 execution' => sub { lives-ok {
            my $python2 = run('python2.7', $testcase, :out, :err);
            ok($python2.exitcode != 0, 'python2 exit code');
        }};
    };
}

done-testing();
