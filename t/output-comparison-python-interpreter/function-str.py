x = str(1)
y = 1

a = [1, 2, 3]
b = {1: 2, 3: 4}
c = (5, 6, 7)

print str(a)
print str(b)
print str(c)

# call to str() without argument returns empty string
print "A%sB" % str()

# only str has capitalize() so abuse it to check if we actually converted
# our __class__ returns the perl class so we can't use that to compare

try:
    print y.capitalize()
except:
    print "int capitalize failed - as expected"

try:
    print x.capitalize()
except:
    print 'str capitalize failed'
