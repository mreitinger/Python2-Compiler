class Foo:
    x = 1
    def bar(self):
        print self.x


a = [Foo().bar]
a[0]()
