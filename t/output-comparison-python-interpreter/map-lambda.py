def foo():
    return 5

def bar():
    return 6

def baz():
    return 7

v = [[1], [2], [3]]
w = [2, 3, 4]
x = [{'a': 1}, {'a': 2}, {'a': 3}]
y = [{'a': 4}, {'a': 5}, {'a': 6}]
z = [{'a': foo()}, {'a': bar()}, {'a': baz()}]

print map(lambda value : value['a']*2, x)
print map(lambda a, b : a['a']*b['a'], x, y)
print map(lambda a, b : a['a']*b['a'], x, z)
print map(lambda a, b : a['a']*b['a'], z, x)
print map(lambda a, b : a['a']*b['a'], z, z)
print map(lambda a, b, c : a['a']*b['a']*c, z, z, w)
print map(lambda a, b, c, d : a['a']*b['a']*c*d[0], z, z, w, v)
