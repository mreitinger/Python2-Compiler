x = 1

def func():
    x = 2
    print x

def funcx(x):
    print x
    x = 2
    print x

print x

func()
funcx(x)

print x
