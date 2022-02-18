class outer:
    i = 2
    o = 5

    def get_inner(self):
        return self.inner

    def say(self, value):
        print value

    def ret(self, value):
        return value


    def __init__(self):
        class inner:
            o = 3

        self.inner = inner()

o = outer()

# single level
print o.i
o.i = 99
print o.i

# multi-level
print o.inner.o
o.inner.o = 5
print o.inner.o

# objects returned by methods
print o.get_inner().o
o.get_inner().o = [1, 2, 3, 4]
print o.get_inner().o
