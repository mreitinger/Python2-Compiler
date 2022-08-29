use Test;
use lib './lib';

use Python2::Compiler;

subtest "embedding - run script" => sub {
    my Str $input = q:to/END/;
    print 1
    END

    my $compiler = Python2::Compiler.new(
        embedded => 'quux',
    );

    my $generated_perl5_code = $compiler.compile($input);

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();
        $p5->__run__();
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

    is $perl5_output, "1\n", 'output matches';

};

subtest "embedding - run function" => sub {
    my Str $input = q:to/END/;
    def foo(a, b, c, d):
        print a
        print b
        print c
        print d
    END

    my $compiler = Python2::Compiler.new(
        embedded => 'quux',
    );

    my $generated_perl5_code = $compiler.compile($input);

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();
        $p5->__run_function__('foo', [[1, 2, 3, 4], {1 => 2}, 'a', 2]);
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

    is $perl5_output, "[1, 2, 3, 4]\n\{1: 2\}\na\n2\n", 'output matches';
};

subtest "embedding - lambda" => sub {
    my Str $input = q:to/END/;
    def get_lambda_addition():
        return lambda x, y : x + y
    END

    my $compiler = Python2::Compiler.new(
        embedded => 'quux',
    );

    my $generated_perl5_code = $compiler.compile($input);

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();
        my $coderef = $p5->__run_function__('get_lambda_addition');

        # returns our function wrapper - see Function::__tonative__
        $coderef = $$coderef->__tonative__;

        say $coderef->(2, 4);
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

    is $perl5_output, "6\n", 'output matches';
};

subtest "embedding - __getattr__ fallback" => sub {
    my Str $input = q:to/END/;
    def foo(a):
        # we call 'unknown_attr' and expect it to be handled by the __getattr__ fallback
        print a.unknown_attr
    END

    my $compiler = Python2::Compiler.new(
        embedded => 'quux',
    );

    my $generated_perl5_code = $compiler.compile($input);

    $generated_perl5_code ~= q:to/END/;
        {
            package GetAttrTest;

            sub __getattr__     { 'from__getattr__'; }

            sub new { return bless([], shift); }

            1;
        }

        my $obj = GetAttrTest->new();
        my $p5 = Python2::Type::Class::main_quux->new();

        $p5->__run_function__('foo', [$obj]);
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

    is $perl5_output, "from__getattr__\n", 'output matches';
};


subtest "embedding - coderef wrapper" => sub {
    my Str $input = q:to/END/;
    def foo(a):
        x = a.get_coderef()
        x('passed-parameter')
    END

    my $compiler = Python2::Compiler.new(
        embedded => 'quux',
    );

    my $generated_perl5_code = $compiler.compile($input);

    $generated_perl5_code ~= q:to/END/;
        {
            package GetCodeRefTest;

            sub get_coderef {
                return sub { print 'FROM-PERL: ' . shift . "\n"; };
            }

            sub new { return bless([], shift); }

            1;
        }

        my $obj = GetCodeRefTest->new();
        my $p5 = Python2::Type::Class::main_quux->new();

        $p5->__run_function__('foo', [$obj]);
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

    is $perl5_output, "FROM-PERL: passed-parameter\n", 'output matches';
};




done-testing();
