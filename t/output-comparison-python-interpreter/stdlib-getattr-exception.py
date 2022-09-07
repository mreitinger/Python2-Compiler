# this is used to check if a __getattr__ to a stdlib module implemented
# in pure-perl failes as expected
import re

try:
    x = re.doesnotexist
except AttributeError:
    print "getattr to not existing attribute failed, as expected"
