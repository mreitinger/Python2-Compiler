# test to ensure class definitions overwrite function definitions (and the other way around)

def foo():
    print "function foo() called"

foo()


class foo:
    def __init__(self):
        print "class foo created"

foo()


def foo():
    print "function foo() called"

foo()


foo = 'variable x'

try:
    foo()
except:
    print 'call to foo failed, it is now a variable'

print foo


def foo():
    print "function foo() called"

foo()

class foo:
    def __init__(self):
        print "class foo created"

foo()


