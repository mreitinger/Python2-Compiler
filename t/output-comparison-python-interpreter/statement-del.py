x = 1

print x

del x

try:
    print x
except:
    print "printing x after del failed, as expected"

try:
    del x
except:
    print "deleting not existing x failed, as expected"
