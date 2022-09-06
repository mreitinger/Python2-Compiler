try:
    x, y = [1, 2, 3]
except NameError:
    print "caught NameError, failure"
except ValueError:
    print "caught ValueError, as expected"
except:
    print "cauth some exception, failure"
