x = set([4, 1, 2, 3, 1, 2, 3])
y = set([4, 1, 2, 3, 1, 2, 3])
z = set([1, 2, 3, 1, 2, 3, 4])

print x
print x.__len__()
print x == y
print x == z
print x != y
print x != z

for i in x:
    print i
