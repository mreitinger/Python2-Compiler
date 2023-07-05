print chr(34)

try:
    print chr('a')
except TypeError:
    print "chr('a') returned TypeError, as expected"

try:
    print chr()
except TypeError:
    print "chr() returned TypeError, as expected"

