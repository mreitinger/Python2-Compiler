bar  = 0
baz  = [1, 2, 3]
qux  = {4: 5, 6: 7}
quux = [8, 9, 9]
thud = 'asdf'


def foo(x, y, z, a, b):
    print x
    print y
    print z
    print a
    print b

    x = 1
    y[1] = 5
    z[4] = 8
    a = [9, 8, 7]
    b = 'g'

    print x
    print y
    print z
    print a
    print b

foo(bar, baz, qux, quux, thud)

print bar
print baz
print qux
print quux
print thud
