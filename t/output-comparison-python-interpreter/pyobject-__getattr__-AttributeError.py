class foo:
    def bar(self):
        print 1

x = foo()

try:
    x.bar()
except:
    print 'bar() found, as expected'


try:
    x.qux()
except AttributeError:
    print 'qux() not found, as expected'
