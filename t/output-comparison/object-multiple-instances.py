class foo:
    def __init__(self):
        print "__init__ called"
        self.i = 1

x = foo()
y = foo()

print x.i
print y.i

x.i = 2
y.i = 2

print x.i
print y.i
