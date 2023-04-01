import json

# we don't print it since the perl JSON module produces somewhat different output
json.dumps({ 0: [ { 'x': [ 'a', 1, 2 ] } ] })

print json.loads('{"0": [{"x": [0, 1, 2]}]}')['0'][0]['x'];

# key sorting differs, so we can't test multiple keys
# we don't care for now
# some_dict = {
#      'xy': [
#         1, 2, '3', "4"
#     ],
#     '2': [
#         {
#             'k1': "v1"
#         }
#     ]
# }
# print some_dict
# print json.dumps({
#     'xy': []
#     2: []
# })
try:
    print json.dumps({
        0: json
    })
except:
    print 'JSON content not serializable'



