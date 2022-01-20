try:
    print x
except:
    print 'error 1'

if 1:
    try:
        print x
    except:
        print 'error 2'

try:
    x = 1
    print x
except:
    print 'error 3'


try:
    print x
except:
    print 'error 4'
finally:
    print 'done'
