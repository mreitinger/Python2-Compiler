#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = Python2::Internals::Ext		PACKAGE = Python2::Internals::Ext

int
is_string(SV * object)
    CODE:
        RETVAL = SvPOKp(object) ? 1 : 0;
    OUTPUT:
        RETVAL

