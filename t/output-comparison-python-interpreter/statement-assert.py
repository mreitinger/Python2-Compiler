x = 1

try:
    assert x == 1
    print "assertion 1 succeeded, as expected"
except:
    print "assertion 1 failed, failure"

try:
    assert x == 2
    print "assertion 2 succeeded, failure"
except:
    print "assertion 2 failed, as expected"

try:
    assert x == 2, "with message"
    print "assertion 3 succeeded, failure"
except:
    print "assertion 3 failed, as expected"
