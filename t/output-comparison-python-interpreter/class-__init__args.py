class foo:
    x = 2
    n = 3

    print x
    print n

    def __init__(self, new_x, named):
        self.x = new_x
        self.n = named


y = foo(4, named=5)
print y.x
print y.n

