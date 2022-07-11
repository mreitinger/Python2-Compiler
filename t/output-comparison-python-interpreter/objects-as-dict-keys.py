class bar:
    def quux(self):
        print("output")

foo = {}
baz = bar()

foo[baz] = 1

print foo[baz]
foo.keys()[0].quux()
