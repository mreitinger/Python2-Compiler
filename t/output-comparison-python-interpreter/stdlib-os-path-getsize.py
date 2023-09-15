import os

try:
    os.path.getsize('/does/not/exist')
except OSError:
    print("getsize() for not existing file raises OSError, as expected")


try:
    os.path.getsize(1)
except TypeError:
    print("getsize() with invalid arguments raises TypeError, as expected")

try:
    os.path.getsize(1)
except TypeError:
    print("getsize() with no arguments raises TypeError, as expected")


print(os.path.getsize('t/testdata/testfile-size'))

