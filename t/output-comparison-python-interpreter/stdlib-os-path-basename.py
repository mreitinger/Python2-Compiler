from os.path import basename

print basename('/')
print basename('/foo')
print basename('/foo/')
print basename('/foo/bar/baz')

# error handling
try:
    print basename()
except TypeError:
    print "os.path.basename() with empty argument list returnes TypeError, as expected"


# error handling
try:
    print basename(1)
except:
    print "os.path.basename() with invalid failes, as expected"

