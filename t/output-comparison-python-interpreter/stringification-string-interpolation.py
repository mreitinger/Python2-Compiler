x = 1 == 1
y = 1 == 2
print "A %s" % x
print "B %s" % y
print "C %s %s" % (x, y)
print "D %(bar)s %(foo)s" % {'foo': x, 'bar': y}
