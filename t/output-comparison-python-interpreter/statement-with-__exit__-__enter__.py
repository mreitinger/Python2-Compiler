class foo:
    def __exit__(self, a, b, c):
        print 'exit called'

    def __enter__(self):
        return self

    def bar(self):
        print 123

a = foo()

with a as z:
    z.bar()

z.bar()
