def foo(a='default-a', b='default-b'):
    print a
    print b

def bar(c='default-c', d = 'default-d'):
    print c
    print d



foo()
foo('argument-a')
foo('argument-a', 'argument-b')
foo(1, [1, 2, 3, 4])
bar('qux', 'quux')
