#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Gssapi C <-> Ruby binding
require 'mkmf'
`swig -ruby -wall gss.i`
env_cf = ENV['CFLAGS'].nil? ? "" : ENV['CFLAGS'];
env_ld = ENV['LDFLAGS'].nil? ? "" : ENV['LDFLAGS'];
$CFLAGS = env_cf +" "+`/usr/bin/krb5-config gssapi --cflags`
$LDFLAGS = env_ld +" "+`/usr/bin/krb5-config gssapi --libs`
create_makefile('gssi')
