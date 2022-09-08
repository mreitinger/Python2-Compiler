# check to ensure 'Exception' matches all exceptions

try:
    raise StandardError
except Exception, e:
    print "Caught %s" % e


