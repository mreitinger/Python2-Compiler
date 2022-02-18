# single level dict
foo = {}

print foo
foo['a'] = 'A'
print foo

# single level list
bar = [1, 2, 3, 4, 5]

print bar
bar[0] = 'A'
print bar
bar[1] = 'S'
print bar
bar[2] = 'D'
print bar



# list and dict as object instance variables
class baz:
    a = ['a', 'b', 'c', 'd', 'e']
    b = {}

    class quux:
        c = ['i']
        d = {'i': 'n'}

    quux = quux()

qux = baz()

print qux.a
qux.a[0] = 'A'
print qux.a
qux.a[1] = 'B'
print qux.a

print qux.b
qux.b['a'] = 'b'
print qux.b

print qux.quux.c
qux.quux.c[0] = 'I'
print qux.quux.c

print qux.quux.d
qux.quux.d['i'] = 'I'
print qux.quux.d

