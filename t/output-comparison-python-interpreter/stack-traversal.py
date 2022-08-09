x = 1
y = 2

print x

def func():
    # TODO python fails with UnboundLocalError if the variable is present somewhere in the block

    #try:
    #    print x
    #except:
    #    print 'access to undefined x failed'

    print y

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
