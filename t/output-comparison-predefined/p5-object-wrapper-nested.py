p5import JSON as json

x = json()
list = x.decode('[1,"a", [4, 5, 6], {"b": "c", "d": "e"}]')
print list
print(list)

x.canonical([1])

json_string = x.encode(list)

print json_string
