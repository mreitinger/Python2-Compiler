print dict()
print dict({1: 2})

a = {1: 2}
x = dict(a)

print a
print x
x[1] = 3
print a
print x

b = {1: [2, 3, 4]}
print b
c = dict(b)
print c
c[1][0] = 1;
print b
print c

print dict([(1, 2), (3, 4)])
print dict([[1, 2], [3, 4]])
print dict(map(lambda a: (a, a*2), [1, 2, 3, 4]))

try:
    print dict([1, 2])
except TypeError:
    print "call to dict() with invalid parameters raised TypeError, as expected"

