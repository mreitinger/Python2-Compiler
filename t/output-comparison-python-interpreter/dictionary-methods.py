dict = { 1: 2, 'x': 'asdf', 'y': [1, 2, 3, 4]}

for key in sorted(dict.keys()):
    print key
 
for value in sorted(dict.values()):
    print value

dict.clear()
print dict
