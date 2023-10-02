import os

# absolute paths
print os.path.split('/')
print os.path.split('/foo')
print os.path.split('/foo/bar/baz')
print os.path.split('//');

# relative paths
print os.path.split('')
print os.path.split('foo')
print os.path.split('foo/bar')
print os.path.split('foo//bar')

# error handling
try:
    print os.path.split()
except TypeError:
    print "os.path.split() with empty argument list returnes TypeError, as expected"


# error handling
try:
    print os.path.split(1)
except:
    print "os.path.split() with invalid failes, as expected"
