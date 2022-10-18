def foo():
    print 'foo called'

def bar(arg):
    print 'bar called with arg %s' % arg

def baz():
    def qux(arg):
        print 'qux called with arg %s' % arg

    return qux

x = [foo, bar, baz]

x[0]()
x[1]('arg-passed-to-bar')
x[2]()('arg-passed-to-qux')

