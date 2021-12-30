class foo:
    i = 2
    def __init__(self):
        print "__init__ called"
        self.i = 1

x = foo()
print x.i

x.i = 2
print x.i

x.__init__()
print x.i
