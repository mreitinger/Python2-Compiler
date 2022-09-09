import urllib2
import csv

file_like_object = urllib2.urlopen('https://raw.githubusercontent.com/datablist/sample-csv-files/main/files/people/people-1000.csv')
csv = csv.reader(file_like_object, delimiter=' ')

for row in csv:
   print row
