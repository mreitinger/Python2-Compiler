try:
    from datetime import invalid_function
except ImportError:
    print 'Invalid function name raises ImportError, as expected'

try:
    from invalid_module import invalid_function
except ImportError:
    print 'Invalid module name raises ImportError, as expected'

