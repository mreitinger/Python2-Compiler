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

            def bar(self):
                print 'asdf'
                print self.o
                return 'x'

        self.inner = inner()


o = outer()
print o.i
print o.inner.o
print o.get_inner().o
print o.inner.bar()
o.say(o.inner.bar())
o.say(o.ret(o.inner.bar()))
o.say(o.ret([1, 2, 3, 4]))

