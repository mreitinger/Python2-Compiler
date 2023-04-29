def a(*arg):
    print arg

def b(a, *arg):
    print a
    print arg

a(1, 2, 3, 4)
b(1, 2, 3, 4)
