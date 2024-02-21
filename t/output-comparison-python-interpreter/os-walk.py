import os

output = []

for path, subfolders, files in os.walk('t/testdata/os-walk'):
    output.append("%s - %s - %s" % (path, ','.join(subfolders), ','.join(files)))

for line in sorted(output):
    print(line)

# python does not care so neither should we
for path, subfolders, files in os.walk('/does/not/exist'):
    print("%s - %s - %s" % (path, ','.join(subfolders), ','.join(files)))

