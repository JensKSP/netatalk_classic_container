#!/bin/bash

SBINDIR=/sbin
NAME=syslogd
DAEMON=$SBINDIR/$NAME  
SUSE=0

#
# kill the named process(es)
#
killproc() {
	echo "Killing $1..."
	pid=`/usr/bin/ps -e |
	     /usr/bin/grep $1 |
	     /usr/bin/sed -e 's/^  *//' -e 's/ .*//'`
	[ "$pid" != "" ] && kill $pid
}

#
# status of the named process(es)
#
status() {
	pid=`/usr/bin/ps -e |
	     /usr/bin/grep $1 |
	     /usr/bin/sed -e 's/^  *//' -e 's/ .*//'`
	if [ "$pid" != "" ];
	then
		echo "$1 running with pid(s) $pid"
	else
		echo "$1 not running"
	fi
}

startproc() {
	echo "Starting $*..."
	$*
}


# Source function library.
if [ -f /etc/rc.d/init.d/functions ]; then
  . /etc/rc.d/init.d/functions
else
  SUSE=1
fi
  
test -x $DAEMON || exit 0

if [ ! "$SVIlock" = "" ]; then
  unset LOCK
else
  LOCK=/var/lock/subsys/$NAME
fi

RETVAL=0

#
#	See how we were called.
#
case "$1" in
  start)
    # Check if atd is already running
    # RH style
    if [ $SUSE -eq 0 ] && [ ! "$LOCK" = "" ] && [ -f $LOCK ]; then
      exit 0
    fi
    # Caldera Style
    if [ ! "$SVIlock" = "" ] && [ -f $SVIlock ]; then
      exit 0
    fi
    echo -n "Starting $NAME: "

    if [ $SUSE -eq 0 ]; then
      if [ -x /sbin/ssd ]; then
        ssd -S -n $NAME -x $DAEMON -- $OPTIONS
        [ ! "$SVIlock" = "" ] && touch $SVIlock
      else
        daemon $DAEMON
        RETVAL=$?
      fi
    else
      startproc $DAEMON $OPTIONS
    fi
    [ $SUSE -eq 0 ] && [ ! "$LOCK" = "" ] && [ $RETVAL -eq 0 ] && touch $LOCK
    echo
    ;;
  stop)
    echo -n "Stopping $NAME: "
    
    if [ -x /sbin/ssd ]; then
      ssd -K -p /var/run/$NAME.pid -n $NAME
      [ ! "$SVIlock" = "" ] && rm -f $SVIlock
    else
      killproc $DAEMON
      RETVAL=$?
    fi
    [ ! "$LOCK" = "" ] && [ $RETVAL -eq 0 ] && rm -f $LOCK
    echo
    ;;
  reload|restart)
    $0 stop
    $0 start
    RETVAL=$?
    ;;
  status)
    status $SBINDIR/$NAME
    RETVAL=$?
    ;;
  *)
    echo "Usage: /etc/rc.d/init.d/$NAME {start|stop|restart|reload|status}"
    exit 1
esac

exit $RETVAL
