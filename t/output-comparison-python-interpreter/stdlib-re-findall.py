import re
print re.findall(r"\w+ \w+", "foo bar baz foo bar baz")
print re.findall(r"(\w+)", "foo bar baz foo bar baz")
print re.findall(r"(\w+) \w+", "foo bar baz foo bar baz")
print re.findall(r"(\w+) (\w+)", "foo bar baz foo bar baz")
print re.findall(r"(\w+) (?:(bar)|(qux))", "foo bar baz foo bar baz")
