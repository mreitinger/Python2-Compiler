x = str(1)
y = 1

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
