d = { 1: 2, 3: 4 }

for i in d:
    print i

try:
    for i, o in d:
        print i
        print o
except:
    print("for with multiple arguments fails, as expectd")
