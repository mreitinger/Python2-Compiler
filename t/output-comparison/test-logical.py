print(1 if 0 or 0 else 2)
print(3 if 1 or 0 else 4)
print(5 if 1 or 2 else 6)

print(7 if 0 and 0 else 8)
print(9 if 1 and 0 else 10)
print(11 if 1 and 2 else 12)

print(13 if 0 or 1 and 2 else 14)
print(15 if 0 or 1 and not 2 else 16)
print(17 if 0 or 1 and not 0 else 18)
