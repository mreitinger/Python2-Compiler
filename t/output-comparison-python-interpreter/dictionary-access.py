dict = { 1: 2, 'x': 'asdf', 'y': [1, 2, 3, 4]}

print dict[1]
print dict['x']
print dict['y']

for val in sorted(dict['y']):
    print val

