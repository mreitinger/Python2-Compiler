import ElementTree

# TODO: should be
# import xml.etree.ElementTree as ET

svg_multiplier = 1.75
try:
    tree = ElementTree.parse('/non/existent/file')
except:
    print 'No such file or directory'
tree = ElementTree.parse('t/testdata/test.svg')

root = tree.getroot()

view_box        = root.attrib['viewBox']
view_box_values = view_box.split(' ')

width =  float(view_box_values[2]) * float(svg_multiplier)
height = float(view_box_values[3]) * float(svg_multiplier)

print width
print height