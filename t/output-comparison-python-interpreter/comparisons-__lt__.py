types = [
    1, 2, True, False, [], (), (1, ), {}, [1, 2], [1, 2, 3],
    (1, 2), (1, 2, 3), "", "test", {1: 2}, {1: 2, 3: 4},
    "a", "b"
]

for left in types:
    for right in types:
        print "%s < %s with '%s' < '%s': %s" % (type(left), type(right), left, right, left < right)