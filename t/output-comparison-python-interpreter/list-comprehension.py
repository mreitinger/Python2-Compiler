list = [1, 2, 3, 4]
print [x*2 for x in list]
print [x*2 for x in list if x > 2]


# check if 'x in whatever' works as expected
l = [1, 2, 3, 4]
o = [2, 3, 4, 5]

print [x in o for x in l]