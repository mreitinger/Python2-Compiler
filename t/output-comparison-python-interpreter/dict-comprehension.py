pairs = [('a', 1), ('b', 2)]
print {k: v for k, v in pairs}
print {k: v for k, v in pairs if v > 1}
list = ['A', 'B', 'C']
print {k.lower(): 1 for k in list}
