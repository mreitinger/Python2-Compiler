print type([])
print type({})
print type(1)
print type(1.1)
print type('foo')
print type(())

print type([]).__name__

try:
    type()
except TypeError:
    print "TypeError caught for no arguments, as expected"

try:
    type(1, 2, 3, 4)
except TypeError:
    print "TypeError caught for invalid argument count arguments, as expected"

