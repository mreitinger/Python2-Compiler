use Test;
use lib './lib';

use Python2::Compiler;

subtest "embedding - run script" => sub {
    my Str $input = q:to/END/;
    print 1
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

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

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

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

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

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

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

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
        y = a.get_coderef_with_args()
        x('passed-parameter1')

        y('passed-parameter2', named_key = 'named_value')
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        {
            package GetCodeRefTest;

            sub get_coderef {
                return sub { print 'FROM-PERL: ' . shift . "\n"; };
            }

            sub get_coderef_with_args {
                return sub {
                    my ($positionals, $named) = @_;
                    print 'FROM-PERL positional: ' . $positionals->[0] . "\n";
                    print 'FROM-PERL named: ' . $named->{named_key} . "\n";
                };
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

    is $perl5_output, "FROM-PERL: passed-parameter1\nFROM-PERL positional: passed-parameter2\nFROM-PERL named: named_value\n", 'output matches';
};

subtest "embedding - perlobject" => sub {
    my Str $input = q:to/END/;
    def foo(a):
        a.test_method_positional_only('positional-argument')
        a.test_method_named_only(named_key='named_value')
        a.test_method_combined('positional-argument', named_key='named_value')
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        {
            package PerlObjectTest;

            sub test_method_positional_only {
                my ($self, $positional) = @_;

                print "A positional: $positional\n";
            }

            sub test_method_named_only {
                my ($self, $positional, $named) = @_;

                print "B named: $named->{named_key}\n";
            }

            sub test_method_combined {
                my ($self, $positional, $named) = @_;

                print "C positional: $positional->[0]\n";
                print "D named: $named->{named_key}\n";
            }

            sub new { return bless([], shift); }

            1;
        }

        my $obj = PerlObjectTest->new();
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

    my $expected;
    $expected ~= "A positional: positional-argument\n";
    $expected ~= "B named: named_value\n";
    $expected ~= "C positional: positional-argument\n";
    $expected ~= "D named: named_value\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - return-values" => sub {
    my Str $input = q:to/END/;
    def foo(a):
        print a.get_list()
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        {
            package PerlObjectTest;

            sub get_list {
                return ('a', 'b', 'c')
            }

            sub new { return bless([], shift); }

            1;
        }

        my $obj = PerlObjectTest->new();
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

    my $expected;
    $expected ~= "['a', 'b', 'c']\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - __hasattr__ for PerlObject" => sub {
    my Str $input = q:to/END/;
    def foo(a):
        print hasattr(a, 'test_true')
        print hasattr(a, 'test_false')
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        {
            package PerlObjectTest;

            sub test_true {}

            sub new { return bless([], shift); }

            1;
        }

        my $obj = PerlObjectTest->new();
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

    my $expected;
    $expected ~= "True\nFalse\n";

    is $perl5_output, $expected, 'output matches';
};



done-testing();
