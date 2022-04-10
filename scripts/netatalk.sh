#!/bin/sh

/container/scripts/syslogd.init.sh start
/container/scripts/slpd.init.sh start
/container/scripts/netatalk.init.sh start

tail -f /var/log/messages

