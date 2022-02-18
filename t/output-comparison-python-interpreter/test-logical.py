print(1 if 0 or 0 else 2)
print(3 if 1 or 0 else 4)
print(5 if 1 or 2 else 6)

print(7 if 0 and 0 else 8)
print(9 if 1 and 0 else 10)
print(11 if 1 and 2 else 12)

print(13 if 0 or 1 and 2 else 14)
print(15 if 0 or 1 and not 2 else 16)
print(17 if 0 or 1 and not 0 else 18)


def a():
    return 'a'

def b():
    return 'b'

def func_true():
    return 1

def func_false():
    return 0

print(a() if 1 else b())
print(a() if 0 else b())
print(a() if func_true() else b())
print(a() if func_false() else b())


x = 'x'
y = 'y'

print(x if 1 else y)


class classfoo:
    y = [1, { 'a': 'b' }]
    z = 'foo_z'

class classqux:
    y = [2, { 'c': 'd' }]
    z = 'qux_z'


obj_foo = classfoo()
obj_qux = classqux()

print(obj_foo if 1 else obj_qux).z
print(obj_foo if 0 else obj_qux).z

print(obj_foo if 1 else obj_qux).y[0]
print(obj_foo if 0 else obj_qux).y[0]

print(obj_foo if 1 else obj_qux).y[1]['a']
print(obj_foo if 0 else obj_qux).y[1]['c']
