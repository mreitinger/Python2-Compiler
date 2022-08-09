#print 1 and 2 and 3
print "or"
print 0 or 1
print 1 or 0
print 1 or 2
print 0 or 1 or 2
print 3 or 2 or 1
print ""

print "and"
print 0 and 1
print 1 and 0
print 1 and 2
print 4 and False and 0
print ""

print "not"
print 0 or not 1
print 1 or not 0
print 1 or not 2
print 0 or not 1 or 2
print 3 or not 2 or 1

print 0 and not 1
print 1 and not 0
print 1 and not 2
print 4 and not False and 0
print ""

print "combined"
print 1 and 2 or 3 and 4
print 1 or 2 and 3 or 4
print 1 or False and 3 or 4
print 1 or True and 3 and 4
