list = ['a', 'b', 'c']

# enumerate returns a tuple with only two values so this must fail
for x, y, z in enumerate(list):
    print "%i - %s" % (x, y)

