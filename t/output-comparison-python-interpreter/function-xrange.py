try:
    print xrange()
except TypeError:
    print "xrange with 0 arguments raises TypeError, as expected"

try:
    print xrange([])
except TypeError:
    print "xrange with invalid arguments raises TypeError, as expected"


print("step 1 - default")
print "%s %s" % (xrange(-1), list(xrange(-1)))
print "%s %s" % (xrange(10), list(xrange(10)))
print "%s %s" % (xrange(5, 10), list(xrange(5, 10)))
print "%s %s" % (xrange(-5, 10), list(xrange(-5, 10)))
print "%s %s" % (xrange(-5, -10), list(xrange(-5, -10)))
print "%s %s" % (xrange(5, 1), list(xrange(5, 1)))

for step in [1, 2, 3, 10, 100, -1, -2, -3, -10, -100]:
    print("\nstep %i" % step)
    print "%s %s" % (xrange(5, 10, step), list(xrange(5, 10, step)))
    print "%s %s" % (xrange(-5, 10, step), list(xrange(-5, 10, step)))
    print "%s %s" % (xrange(-5, -10, step), list(xrange(-5, -10, step)))
    print "%s %s" % (xrange(5, 1, step), list(xrange(5, 1, step)))

