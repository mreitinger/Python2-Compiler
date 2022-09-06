try:
    x, y = [1, 2, 3]
except NameError:
    print "caught NameError, failure"
except ValueError, e:
    print "caught ValueError, as expected: %s" % e
except:
    print "cauth some exception, failure"
