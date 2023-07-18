import urllib

print urllib.urlopen('https://google.com').info().getheader('Content-Type')
print urllib.urlopen('https://google.com').info().getheader('Does-Not-Exist')

print urllib.urlopen('https://google.com').info().get('Content-Type')
print urllib.urlopen('https://google.com').info().get('Does-Not-Exist')

