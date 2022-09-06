a, b = [1, 2]

print a
print b

try:
    c, d = [3, 4, 5]
except:
    print "assignment with too many values failed, as expected"
