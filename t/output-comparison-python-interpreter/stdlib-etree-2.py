# coding=utf-8
import xml.etree.ElementTree as xml

tree = xml.parse('t/testdata/rss-test.xml')
root = tree.getroot()

print(root.find('channel/title').text)

for elem in root.findall('channel/item'):
    print(elem.find('title').text)
