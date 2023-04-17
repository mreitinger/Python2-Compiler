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
print type(foo)
print foo

def foo():
    print "function foo() called"

foo()

class foo:
    def __init__(self):
        print "class foo created"

foo()


