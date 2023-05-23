x = [1, 2, 3, 4, 5]
i = iter(x)
print i.next()
print i.next()
print sorted(i)

try:
    print i.next()
except StopIteration:
    print "completed iterator returned StopIteration, as expected"

