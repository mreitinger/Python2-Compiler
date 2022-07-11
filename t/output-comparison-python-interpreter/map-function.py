def multiply1(a):
    return a*2

def multiply2(a, b):
    return a*b



x = [2, 3, 4]
y = [5, 6, 7]

print map(multiply1, x)
print map(multiply2, x, y)
