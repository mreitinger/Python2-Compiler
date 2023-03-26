j = perl.JSON.new('JSON')

print j.encode([1, 2, 3, 4, 'a', 'b', 'c', 'd', { 1: 2 }, { 'a': [5, 6, 7, 8] }])

