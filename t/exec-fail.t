use Test;
use lib './lib';

use Python2::Grammar;
use Python2::Actions;
use Python2::Backend::Perl5;
use Python2::Compiler;

# used for module compilation
my $compiler = Python2::Compiler.new();

my $testcase_directory = IO::Path.new("./t/exec-fail");

unless $testcase_directory.e {
    die("Testcase directory not found, are you running tests from the wrong directory?");
}

%*ENV<PYTHONPATH> = './t/pylib';

for $testcase_directory.dir -> $testcase {
    subtest $testcase => sub {
        my $generated_perl5_code = Nil;
        my $parsed = Nil;
        my $ast = Nil;

        subtest "Parser for $testcase" => sub {
            $parsed = Python2::Grammar.parse($testcase.slurp, actions => Python2::Actions);
        };
        $parsed or flunk("Parser failed for $testcase");


        subtest "AST for $testcase" => sub {
            $ast = $parsed.made;
        };
        $ast or flunk("AST generation failed for $testcase");


        subtest "Perl 5 code generation for $testcase" => sub {
            my $backend = Python2::Backend::Perl5.new(:$compiler);
            ok($generated_perl5_code = $backend.e($ast));
        };
        $generated_perl5_code or flunk("Failed to generate Perl 5 code for $testcase");


        subtest "Perl 5 execution $testcase (expecting failure)" => sub {
            my $perl5;
            try {
                $perl5 = run('perl', :in, :out, :err);
                $perl5.in.say($generated_perl5_code);
                $perl5.in.close;
                1; # to make the try{} not fail - TODO there is probably a nicer way to do this
            };

            ok($perl5.exitcode != 0, 'perl5 exit code');
        };


        # check that python2 failes as well
        subtest 'Python 2 execution' => sub { lives-ok {
            my $python2 = run('python2.7', $testcase, :out, :err);
            ok($python2.exitcode != 0, 'python2 exit code');
        }};
    };
}

done-testing();
