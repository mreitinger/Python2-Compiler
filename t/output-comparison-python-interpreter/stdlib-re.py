import re

x = 'foobar'

print x
print re.sub(r'bar$', 'qux', x)
