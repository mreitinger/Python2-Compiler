a = {}
b = []
l = [1, 2, 3, a, [], {}]

print(l)

for i in [1, a, [], {}]:
    l.remove(i)
    print(l)

try:
    l.remove(-1)
except ValueError:
    print("not existing element raised ValueError, as expected")
