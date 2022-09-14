def my_filter(item):
    return item > 2 and item < 5

print filter(lambda item: item > 1 and item < 4, [0, 1, 2, 3, 4, 5, 6, 7])
print filter(my_filter, [0, 1, 2, 3, 4, 5, 6, 7])

