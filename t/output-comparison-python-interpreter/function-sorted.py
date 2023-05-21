print sorted([5, 4, 1, 2, 3])
print sorted(['b', 'c', 'd', 'a', 'f'])
print sorted([5, 2, 'a', 'c', 'b'])

def t(b):
    return b.lower()

print sorted("Test string A b C".split())
print sorted("Test string A b C".split(), key=t)
print sorted("Test string A b C".split(), key=lambda s: s.lower())
