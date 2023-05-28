pairs = [('a', 1), ('b', 2)]
print sorted({k: v for k, v in pairs}.items(), key=lambda t: t[0])
print sorted({k: v for k, v in pairs if v > 1}.items(), key=lambda t: t[0])
list = ['A', 'B', 'C']
print sorted({k.lower(): 1 for k in list}.items(), key=lambda t: t[0])
