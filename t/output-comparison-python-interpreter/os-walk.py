import os

for path, subfolders, files in os.walk('t/testdata/os-walk'):
    print("%s - %s - %s" % (path, ','.join(subfolders), ','.join(files)))

# python does not care so neither should we
for path, subfolders, files in os.walk('/does/not/exist'):
    print("%s - %s - %s" % (path, ','.join(subfolders), ','.join(files)))

