#!/bin/bash
# Nate Murray <nmurray@attinterative.com>
# Date 2009-07-13
# 
# Record number of invalid users or failed passwords in sshd

# Also check if this is the right location of gmetric
GMETRIC=/usr/bin/gmetric
AUTH_LOG=/var/log/auth.log

COUNT=$(cat $AUTH_LOG | grep -iE "(Invalid user|Failed password)" | grep "`date '+%b %e'`" | wc -l)
$GMETRIC --name "failed-or-invalid-login-attempts" --value $COUNT --type uint8 --units ''
exit 0
