#!/usr/bin/expect

###############################################################################
#Script Name    : redis.sh
#Description    : Key Count of multiple Redis-XXX servers
#Author         : XXX
#Email          : XXX
################################################################################

set prompt "(%|#|\\$) $"
set HOST [lindex $argv 0]
set PASS [lindex $argv 1]
set timeout 90
set f [open "IP_HostNames"]
set values [split [read -nonewline $f]]
close $f
foreach i $values {
spawn ssh -q $HOST@$i
expect "yes/no" {
        send "yes\r"
        expect ": " { send "$PASS\r" }
        } ": " {send "$PASS\r" }
expect -re  $prompt
                 send "sudo docker exec redis redis-cli info keyspace|grep -i db0 | cut -d, -f1\r"
                 expect ": " {
                 send "$PASS\r"
                 } ": " { send "$PASS\r" }
expect -re $prompt
                send "exit\r"
interact
}
