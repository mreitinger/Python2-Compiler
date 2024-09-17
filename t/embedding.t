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
        $p5->__run_function__('foo', [
            [1, 2, 3, 4], {1 => 2}, 'a', 2,
            bless({}, 'Python2::NamedArgumentsHash')
        ]);
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
        my $coderef = $p5->__run_function__(
            'get_lambda_addition',
            [ bless({}, 'Python2::NamedArgumentsHash') ]
        );

        # returns our function wrapper - see Function::__tonative__
        $coderef = $coderef->__tonative__;

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

        $p5->__run_function__('foo', [$obj, bless({}, 'Python2::NamedArgumentsHash')]);
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

        $p5->__run_function__('foo', [$obj, bless({}, 'Python2::NamedArgumentsHash')]);
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

        # no function call!
        print a.test_method_getattr_fallback
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        {
            package PerlObjectTest;

            sub test_method_getattr_fallback {
                return '__getattr__ fallback retval';
            }

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

        $p5->__run_function__('foo', [$obj, bless({}, 'Python2::NamedArgumentsHash')]);
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
    $expected ~= "__getattr__ fallback retval\n";

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

        $p5->__run_function__('foo', [$obj, bless({}, 'Python2::NamedArgumentsHash')]);
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
    def foo(a, b):
        print hasattr(a, 'test_true')
        print hasattr(a, 'test_false')
        print hasattr(b, 'test_true')
        print hasattr(b, 'test_false')
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

        {
            package PerlObjectTestWithHasAttr;

            sub __hasattr__ {
                my ($self, $attr) = @_;

                return 1 if $attr eq 'test_true';
                return 0;
            }

            sub new { return bless([], shift); }

            1;
        }

        my $obj = PerlObjectTest->new();
        my $obj_implementing_hasattr = PerlObjectTestWithHasAttr->new();
        my $p5 = Python2::Type::Class::main_quux->new();

        $p5->__run_function__('foo', [
            $obj, $obj_implementing_hasattr,
            bless({}, 'Python2::NamedArgumentsHash')
        ]);
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
    $expected ~= "True\nFalse\nTrue\nFalse\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - __str__ for PerlObject" => sub {
    my Str $input = q:to/END/;
    def foo(a, b):
        print a

        try:
            print b
        except NotImplementedError:
            print "Got NotImplementedError for object without __str__, as expected"
        except:
            print "Got other exception, failure."
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        {
            package PerlObjectTestWithStr;

            sub __str__ { '__str__-called' }

            sub new { return bless([], shift); }

            1;
        }

        {
            package PerlObjectTestWithoutStr;

            sub new { return bless([], shift); }

            1;
        }

        my $with    = PerlObjectTestWithStr->new();
        my $without = PerlObjectTestWithoutStr->new();
        my $p5 = Python2::Type::Class::main_quux->new();

        $p5->__run_function__('foo', [$with, $without, bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected
        = "__str__-called\nGot NotImplementedError for object without __str__, as expected\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - __len__ for PerlObject" => sub {
    my Str $input = q:to/END/;
    def foo(a, b):
        print len(a)

        try:
            print len(b)
        except NotImplementedError:
            print "Got NotImplementedError for object without __str__, as expected"
        except:
            print "Got other exception, failure."
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        {
            package PerlObjectTestWithStr;

            sub __str__ { '__str__-called' }

            sub new { return bless([], shift); }

            1;
        }

        {
            package PerlObjectTestWithoutStr;

            sub new { return bless([], shift); }

            1;
        }

        my $with    = PerlObjectTestWithStr->new();
        my $without = PerlObjectTestWithoutStr->new();
        my $p5 = Python2::Type::Class::main_quux->new();

        $p5->__run_function__('foo', [$with, $without, bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected
        = "14\nGot NotImplementedError for object without __str__, as expected\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - update external hash" => sub {
    my Str $input = q:to/END/;
    def foo(a):
        a['key'] = 'new value'
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $hash = { 'key' => 'initial value' };

        # initial value
        say $hash->{key};

        # must update the 'external' hash (= get wrapped intl a PerlHash not Dict object)
        $p5->__run_function__('foo', [$hash, bless({}, 'Python2::NamedArgumentsHash')]);

        # updated value
        say $hash->{key};
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

    my $expected
        = "initial value\nnew value\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - update external list" => sub {
    my Str $input = q:to/END/;
    def foo(a):
        a[0] = 'new value'
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $list = ['initial value'];

        # initial value
        say $list->[0];

        # must update the 'external' hash (= get wrapped intl a PerlHash not Dict object)
        $p5->__run_function__('foo', [$list, bless({}, 'Python2::NamedArgumentsHash')]);

        # updated value
        say $list->[0];
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

    my $expected
        = "initial value\nnew value\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - PerlArray list comprehension" => sub {
    my Str $input = q:to/END/;
    def f(a):
        print(a)

    def foo(a):
        [f(item) for item in a]
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $list = ['value 1', 'value 2', 'value 3'];

        $p5->__run_function__('foo', [$list, bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected = "value 1\nvalue 2\nvalue 3\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - PerlArray __getslice__" => sub {
    my Str $input = q:to/END/;
    def foo(a):
        print(a[0])
        print(a[0:1])
        print(a[0:3])
        print(a[0:5])
        print(a[5:5])
        print(a[:2])
        print(a[2:])
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $list_of_int = [1, 2, 3];
        my $list_of_str = ['1', '2', '3'];

        $p5->__run_function__('foo', [$list_of_int, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('foo', [$list_of_str, bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected =  "1\n\[1\]\n\[1, 2, 3\]\n\[1, 2, 3\]\n\[\]\n\[1, 2\]\n\[3\]\n";
    $expected    ~= "1\n\['1'\]\n\['1', '2', '3'\]\n\['1', '2', '3'\]\n\[\]\n\['1', '2'\]\n\['3'\]\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - PerlArray __eq__" => sub {
    my Str $input = q:to/END/;
    def eq1(a, b):
        print(a == b)

    def eq2(a):
        b = [1, 2, 3]
        print(a == b)
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $list = ['1', '2', '3'];
        my $list2 = ['1', '2', '3'];
        my $list3 = ['4', '5', '6'];

        $p5->__run_function__('eq1', [$list, $list, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('eq1', [$list, $list2, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('eq1', [$list, $list3, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('eq2', [$list, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('eq2', [$list3, bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected = "True\nTrue\nFalse\nFalse\nFalse\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - PerlArray __lt__" => sub {
    my Str $input = q:to/END/;
    def lt(a, b):
        print "%s > %s results in %s" % (type(a).__name__,  type(b).__name__, a > b)
        print "%s > %s results in %s" % (type([]).__name__, type(b).__name__, [] > b)
        print "%s < %s results in %s" % (type([]).__name__, type(b).__name__, [] < b)
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $list = ['1', '2', '3'];
        my $list2 = ['1', '2', '3'];

        $p5->__run_function__('lt', [$list, 1, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('lt', [$list, "1", bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('lt', [$list, {}, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('lt', [$list, [], bless({}, 'Python2::NamedArgumentsHash')]);
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
    $expected ~= "list > int results in True\n";
    $expected ~= "list > int results in True\n";
    $expected ~= "list < int results in False\n";
    $expected ~= "list > str results in False\n";
    $expected ~= "list > str results in False\n";
    $expected ~= "list < str results in True\n";
    $expected ~= "list > dict results in True\n";
    $expected ~= "list > dict results in True\n";
    $expected ~= "list < dict results in False\n";
    $expected ~= "list > list results in False\n";
    $expected ~= "list > list results in False\n";
    $expected ~= "list < list results in False\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - PerlArray remove" => sub {
    my Str $input = q:to/END/;
    def r(haystack, needle):
        haystack.remove(needle)
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $list = ['1', '2', '3', 'a'];

        $p5->__run_function__('r', [$list, '1', bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('r', [$list, 'a', bless({}, 'Python2::NamedArgumentsHash')]);
        print join(",", @$list) . "\n";
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

    my $expected = "2,3\n";

    is $perl5_output, $expected, 'output matches';
};


subtest "embedding - PerlHash __contains__" => sub {
    my Str $input = q:to/END/;
    def check(a, b):
        print a in b
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $hash = {
            'a' => 'b'
        };

        $p5->__run_function__('check', ['a', $hash, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('check', ['b', $hash, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('check', ['c', $hash, bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected = "True\nFalse\nFalse\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - PerlHash iteration" => sub {
    my Str $input = q:to/END/;
    def t(d):
        a = []
        for i in d:
            a.append(i)
        print sorted(a)
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $hash = {
            'a' => 'b',
            'c' => 'd'
        };

        $p5->__run_function__('t', [$hash, bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected = "['a', 'c']\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - dualvar" => sub {
    my Str $input = q:to/END/;
    def t(d):
        if d > 0:
            print 1
        else:
            print 2
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $hash = {
            'a' => 'b',
            'c' => 'd'
        };

        $p5->__run_function__('t', [exists $hash->{a}, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('t', [exists $hash->{b}, bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected = "1\n2\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - string conversion" => sub {
    my Str $input = q:to/END/;
    def get_type(a):
        print type(a).__name__

    def test_string(a):
        # replace only exists on a string - if a quoted number ("1") was
        # detected as number this would fail.
        print a.replace('1', '2')
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        $p5->__run_function__('get_type', [1, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('get_type', ['1', bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('test_string', ['1', bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected = "int\nstr\n2\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - PerlArray sorting" => sub {
    my Str $input = q:to/END/;
    def sort_plain(a):
        a.sort()

    def sort_key(a):
        a.sort(key=lambda a: a.lower())

    def sort_reverse(a):
        a.sort(reverse=True)

    def sort_both(a):
        a.sort(reverse=True, key=lambda a: a.lower())
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $list = ['Test', 'string', 'A', 'b', 'C'];

        $p5->__run_function__('sort_plain', [$list, bless({}, 'Python2::NamedArgumentsHash')]);
        print(join(" ", @$list) . "\n");

        $p5->__run_function__('sort_key', [$list, bless({}, 'Python2::NamedArgumentsHash')]);
        print(join(" ", @$list) . "\n");

        $p5->__run_function__('sort_reverse', [$list, bless({}, 'Python2::NamedArgumentsHash')]);
        print(join(" ", @$list) . "\n");

        $p5->__run_function__('sort_both', [$list, bless({}, 'Python2::NamedArgumentsHash')]);
        print(join(" ", @$list) . "\n");
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

    my $expected =  "A C Test b string\n";
    $expected    ~= "A b C string Test\n";
    $expected    ~= "string b Test C A\n";
    $expected    ~= "Test string C b A\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - bool conversion" => sub {
    my Str $input = q:to/END/;
    def get_true():
        return True

    def get_false():
        return False
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $true  = $p5->__run_function__('get_true',  [bless({}, 'Python2::NamedArgumentsHash')])->__tonative__;
        my $false = $p5->__run_function__('get_false', [bless({}, 'Python2::NamedArgumentsHash')])->__tonative__;

        print "true-is-one\n" if $true == 1;
        print "false-is-zero\n" if $false == 0;
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

    my $expected = "true-is-one\nfalse-is-zero\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - __cmp__ support" => sub {
    my Str $input = q:to/END/;
    def a(a, b):
        if a == b:
            print 'a == b, as expected with __cmp__ support'
        else:
            print 'a != b, failure'

    def b(c, d):
        if c != d:
            print 'c != d, as expected'
        else:
            print 'c == d, failure'
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        {
            package PerlObjectTest;

            sub __cmp__ {
                0;
            }

            sub new { return bless([], shift); }

            1;
        }

        my $obj1 = PerlObjectTest->new();
        my $obj2 = PerlObjectTest->new();

        my $p5 = Python2::Type::Class::main_quux->new();

        $p5->__run_function__('a', [$obj1, $obj2, bless({}, 'Python2::NamedArgumentsHash')]);
        $p5->__run_function__('b', [$obj1, undef, bless({}, 'Python2::NamedArgumentsHash')]);
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

    my $expected = "a == b, as expected with __cmp__ support\nc != d, as expected\n";

    is $perl5_output, $expected, 'output matches';
};

subtest "embedding - PerlArray.reverse()" => sub {
    my Str $input = q:to/END/;
    def a(a):
        a.reverse()
    END

    my $compiler = Python2::Compiler.new();

    my $generated_perl5_code = $compiler.compile($input, :embedded('quux'));

    $generated_perl5_code ~= q:to/END/;
        my $p5 = Python2::Type::Class::main_quux->new();

        my $list = [1, 2, 3, 4];
        print join(",", @$list) . "\n";

        $p5->__run_function__('a', [$list, bless({}, 'Python2::NamedArgumentsHash')]);
        print join(",", @$list) . "\n";

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

    my $expected = "1,2,3,4\n4,3,2,1\n";

    is $perl5_output, $expected, 'output matches';
};



done-testing();
