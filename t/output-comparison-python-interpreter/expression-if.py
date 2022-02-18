x = 'x'
y = 'y'
var_f = 0
var_t = 1

def func_f():
    return 0

def func_t():
    return 1 

print(2 if 0 else 3)
print(2 if 1 else 3)

print(x if 0 else y)
print(x if 1 else y)

print(x if func_f else y)
print(x if func_t else y)

print(x if func_f() else y)
print(x if func_t() else y)

print(1 if 2 else 3 if 4 else 5)
print(1 if 0 else 3 if 4 else 5)
