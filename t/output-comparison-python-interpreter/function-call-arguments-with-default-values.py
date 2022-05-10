def foo(a='default-a', b='default-b'):
    print a
    print b

foo()
foo('argument-a')
foo('argument-a', 'argument-b')
foo(1, [1, 2, 3, 4])
