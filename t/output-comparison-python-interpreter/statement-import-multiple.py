import json, base64
import json as j, base64 as b

json.dumps({ 0: [ { 'x': [ 'a', 1, 2 ] } ] })
print base64.b64encode('foo')

j.dumps({ 0: [ { 'x': [ 'a', 1, 2 ] } ] })
print b.b64encode('foo')
