x = 1

print x

def func():
    try:
        print x
    except:
        print 'access to undefined x failed'

    print 'func() body executed'
    x = 2
    print x

print x

def funcx(x):
    print 'funcx() body executed'
    print x
    x = 3
    print x

print x

func()
print x

funcx(x)
print x
