import json

print json.dumps({ 0: [ {} ] })
print json.dumps({
     'xy': [
        1, 2, '3', "4"
    ],
    '2': [
        {
            'k1': "v1"
        }
    ]
})
# TODO: key sorting differs in case of varying key data-types
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



