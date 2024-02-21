x = [(3, 2, 6), (2, 2, 6), (4, 2, 5), (1, 2, 4), ('b', 'c', 'd'), ('a', 'b', 'c'), ('A', 'B', 'C')]

print sorted(x)
print sorted(x, key=lambda s: s[2])
