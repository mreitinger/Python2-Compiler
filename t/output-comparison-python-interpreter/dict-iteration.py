d = { 1: 2, 3: 4 }

a = []
for i in d:
    a.append(i)
print sorted(a)

try:
    for i, o in d:
        print i
        print o
except:
    print("for with multiple arguments fails, as expectd")
