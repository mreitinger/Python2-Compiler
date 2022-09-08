try:
    raise Exception('message 1')
except Exception, e:
    print "Got Exception with message '%s'" % e

try:
    raise Exception, 'message 2'
except Exception, e:
    print "Got Exception with message '%s'" % e
