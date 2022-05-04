a = [1, 2, 3]
b = a
c = None

if a is b:
    print 1

if 1 is 1:
    print 2

if 1 is 2:
    print 3

if a is [1, 2, 3]:
    print 4

if b is [1, 2, 3]:
    print 5

if b is a:
    print 6

if b is None:
    print 7

if a is None:
    print 8

if c is None:
    print 9

if None is None:
    print 10
