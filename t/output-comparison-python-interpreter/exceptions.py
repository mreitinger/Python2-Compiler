try:
    raise Exception
except Exception:
    print 'caught correct exception Exception'
except:
    print 'fallback - exception did not match, failure'

try:
    raise StandardError
except StandardError:
    print 'caught correct exception StandardError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise ArithmeticError
except ArithmeticError:
    print 'caught correct exception ArithmeticError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise LookupError
except LookupError:
    print 'caught correct exception LookupError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise AssertionError
except AssertionError:
    print 'caught correct exception AssertionError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise AttributeError
except AttributeError:
    print 'caught correct exception AttributeError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise EOFError
except EOFError:
    print 'caught correct exception EOFError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise EnvironmentError
except EnvironmentError:
    print 'caught correct exception EnvironmentError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise FloatingPointError
except FloatingPointError:
    print 'caught correct exception FloatingPointError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise IOError
except IOError:
    print 'caught correct exception IOError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise ImportError
except ImportError:
    print 'caught correct exception ImportError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise IndexError
except IndexError:
    print 'caught correct exception IndexError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise KeyError
except KeyError:
    print 'caught correct exception KeyError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise KeyboardInterrupt
except KeyboardInterrupt:
    print 'caught correct exception KeyboardInterrupt'
except:
    print 'fallback - exception did not match, failure'

try:
    raise MemoryError
except MemoryError:
    print 'caught correct exception MemoryError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise NameError
except NameError:
    print 'caught correct exception NameError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise NotImplementedError
except NotImplementedError:
    print 'caught correct exception NotImplementedError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise OSError
except OSError:
    print 'caught correct exception OSError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise OverflowError
except OverflowError:
    print 'caught correct exception OverflowError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise ReferenceError
except ReferenceError:
    print 'caught correct exception ReferenceError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise RuntimeError
except RuntimeError:
    print 'caught correct exception RuntimeError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise StopIteration
except StopIteration:
    print 'caught correct exception StopIteration'
except:
    print 'fallback - exception did not match, failure'

try:
    raise SyntaxError
except SyntaxError:
    print 'caught correct exception SyntaxError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise SystemError
except SystemError:
    print 'caught correct exception SystemError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise SystemExit
except SystemExit:
    print 'caught correct exception SystemExit'
except:
    print 'fallback - exception did not match, failure'

try:
    raise TypeError
except TypeError:
    print 'caught correct exception TypeError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise ValueError
except ValueError:
    print 'caught correct exception ValueError'
except:
    print 'fallback - exception did not match, failure'

try:
    raise ZeroDivisionError
except ZeroDivisionError:
    print 'caught correct exception ZeroDivisionError'
except:
    print 'fallback - exception did not match, failure'

