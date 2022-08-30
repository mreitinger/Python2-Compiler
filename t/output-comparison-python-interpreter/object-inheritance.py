class base:
    x = 1
    z = 3

    def base_method(self):
        print self.x

    def replaced_method(self):
        print "base %s" % self.x

class inner(base):
    y = 2
    z = 4

    def inner_method(self):
        print self.x
        print self.y

    def replaced_method(self):
        print "inner %s" % self.x

a = base()
print a.z
a.base_method()

b = inner()
c = base()

print b.x
print b.y

a.base_method()
print a.z

b.base_method()
b.inner_method()
b.replaced_method()

a.base_method()
print a.z
