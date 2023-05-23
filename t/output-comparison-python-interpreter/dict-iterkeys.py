d = { 1: 2, 3: 4, 5: 6 }

for i in d.iterkeys():
    print i

for i in sorted(d.iterkeys()):
    print i

for i in enumerate(d.iterkeys()):
    print i
