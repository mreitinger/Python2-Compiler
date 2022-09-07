# coding=utf-8
import urllib

print urllib.quote_plus(' -._~abcdEFGH\! "§$%&/()=?+*#;,/ ', safe='')
print urllib.quote(' -._~abcdEFGH\! "§$%&/()=?+*#;,/ ', safe='')


