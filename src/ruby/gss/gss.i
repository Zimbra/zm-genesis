/*  
#
# $File: //depot/main/ZimbraQA/src/ruby/runtest.rb $ 
# $DateTime: 2008/03/25 16:54:03 $
#
# $Revision: #36 $
# $Author: bhwang $
# 
# Gssapi C <-> Ruby binding
*/
%module gss
%{
/* Put headers and other declarations here */
#include "/usr/include/gssapi/gssapi.h"
%}
/* Keep track of mappings between C/C++ structs/classes
and Ruby objects so we can implement a mark function */
%trackobjects;

%typemap(in) OM_uint32 {
        $1 = NUM2UINT($input);
}

%include "/usr/include/gssapi/gssapi.h"

