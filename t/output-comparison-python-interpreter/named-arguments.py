def foo(a, b, c=99):
    print a
    print b
    print c

foo(1, 2, 3)
foo(4, 5, c=6)
foo(a=7, b=8, c=9)
foo(10, 11)
