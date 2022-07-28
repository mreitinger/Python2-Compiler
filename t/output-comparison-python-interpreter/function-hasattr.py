x = {}
y = []

class foo:
    z = 1

bar = foo()

print hasattr(x, 'does_not_exist')
print hasattr(x, '__len__')

print hasattr(y, 'does_not_exist')
print hasattr(y, '__len__')

print hasattr(bar, 'does_not_exist')
print hasattr(bar, 'z')

