try:
    print None()
except TypeError:
    print 'None.__call__ raised TypeError, as expected'

try:
    x = [None]
    print x[0]()
except TypeError:
    print 'None.__call__ while nested raised TypeError, as expected'

