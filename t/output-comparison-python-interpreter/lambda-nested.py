import json

vals=[1, 2, 3, 4]

def b(var):
    print('got %s' % json.dumps(var))
    return 1

x = map(lambda uid: lambda search: b(uid), vals)

for v in x:
    print(v(1))
