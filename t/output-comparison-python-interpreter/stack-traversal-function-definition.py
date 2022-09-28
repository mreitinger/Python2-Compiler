def foo():
    x = 1

    def bar():
        y = 2
        print x

    return bar

x = 2

f = foo()
f()
