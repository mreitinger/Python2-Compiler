import os

# absolute paths
print os.path.join('/')
print os.path.join('/', 'foo')
print os.path.join('/', 'foo', '/', 'bar')

# relative paths
print os.path.join('foo')
print os.path.join('foo', 'bar')

# error handling
try:
    print os.path.join()
except TypeError:
    print "os.path.join() with empty argument list returnes TypeError, as expected"


# error handling
try:
    print os.path.join('a', 1, 'b')
except:
    print "os.path.join() with invalid failes, as expected"
