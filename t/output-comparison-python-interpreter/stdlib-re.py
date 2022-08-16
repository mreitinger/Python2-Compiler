import re

x = 'a b c A B C'

# flag verbose
print re.sub('''
^
a
''', 'foo', x, flags=re.VERBOSE)

print re.sub('''
^
a
''', 'foo', x)

# flag ignorecase
print re.sub('a', 'foo', x, flags=re.IGNORECASE)
print re.sub('a', 'foo', x)

# flag both
print re.sub('''
a
''', 'foo', x, flags=re.VERBOSE | re.IGNORECASE)

print re.sub('''
^
a
''', 'foo', x)

