def a():
    return 1

def b():
    return 'asdf'

def c():
    return [1, 2, 3, 4]

def d():
    return {1: 2}

def e():
    x = 'e'
    return x

def f():
    def foo():
        return ['asdf']

    return foo()

def g():
    if 1:
        return

    print 'did-not-return'

def h():
    return 1 == 2

def i():
    return 1 == 1

def j():
    return (1, 2, 3)



print a()
print b()
print c()
print d()
print e()
print f()
g()
print "A %s" % h()
print "B %s" % i()
print "C %s %s" % (h(), i())
print j()
