p5import JSON as json

x = json()
list = x.decode('[1,2,3,4,"a","b","c","d"]')
print list
json_string = x.encode(list)
print json_string
