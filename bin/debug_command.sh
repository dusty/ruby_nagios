#!/bin/bash
command=/opt/nagios-custom-plugins/bin/snmp_check_procs.rb
cmd=/tmp/nag.cmd
out=/tmp/nag.out
err=/tmp/nag.err

echo "${command} $*" > $cmd 
eval "./${command} $*" > $out 2> $err 
