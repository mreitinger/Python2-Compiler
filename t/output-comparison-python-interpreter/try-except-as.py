try:
    raise Exception('foo')
except Exception as e:
    print e
except:
    print 'did not catch'

