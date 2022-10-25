def foo(arg1):
    print arg1

def bar():
    return ['a', 'b', 'c']

def baz(pos):
    return ['d', 'e', 'f'][pos]

(lambda x: foo(x))('arg1')
print (lambda x: bar())(0)[0]
print (lambda x: baz(x))(0)
