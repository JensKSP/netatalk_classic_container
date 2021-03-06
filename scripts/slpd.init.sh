#!/bin/bash
#
#	/etc/rc.d/init.d/slpd
#
# slpd    Start/Stop the OpenSLP SA daemon (slpd).
#
# chkconfig: 345 13 87
# description: OpenSLP daemon for the Service Location Protocol
# processname: slpd

# Author: Miquel van Smoorenburg, <miquels@drinkel.nl.mugnet.org>
#     Modified for RHS Linux by Damien Neil
#     Modified for COL by Raymund Will, <ray@lst.de>
#     Modified for OpenSLP by Matt Peterson <mpeterson@calderasystems.com>
#     Modified to be distribution agnostic by Bart Whiteley <bart@caldera.com>

#//////////////////////////////////////////////////#
# Does nothing if a route exists that supports     # 
# multicast traffic. If no routes supporting       #
# multicast traffic exists, the function tries to  #
# add one.  A 0 is returned on success and a 1     #
# on failure. One parameter must be passed in.     #
# This variable determins verbosity. If parameter  #
# is non-zero debugging will appear                #
#//////////////////////////////////////////////////#
multicast_route_set() 
{
    PING_OPTIONS_1='-c1 -w1'
    PING_OPTIONS_2='-c1 -i1'
    MULTICAST_ADDRESS='239.255.255.253'
    PING_ERROR_NO_ROUTE='unreachable'

    MSG_FAILED_TO_FIND='Failed to Detect Multicast Route'
    MSG_SUCCESS_ON_FIND='Multicast Route Enabled'
    MSG_ADDING_ROUTE='Attempting to Add Multicast Route ...'
    MSG_FAILED_TO_ADD=' FAILED - Route NOT Added.'
    MSG_SUCCES_ON_ADD=' SUCCESS - Route Added.'

    CMD_GET_INTERFACE="netstat -i | awk 'BEGIN{}(NR>2)&&(!/^lo*/){print \$1}'"
    CMD_ADD_ROUTE="route add -net 224.0.0.0 netmask 240.0.0.0"

    err_unreachable_found=`ping $PING_OPTIONS_1 $MULTICAST_ADDRESS 2>&1 1>/dev/null`

	if [ $? = 2 ]; then
        err_unreachable_found=`ping $PING_OPTIONS_2 $MULTICAST_ADDRESS 2>&1 1>/dev/null`
	fi


    #If errors, add route. Otherwise, do nothing
    if [ "$err_unreachable_found" ]; then 

        if [ $1 != 0 ]; then
            echo $MSG_FAILED_TO_FIND 
            echo $MSG_ADDING_ROUTE 
        fi

        $CMD_ADD_ROUTE `eval $CMD_GET_INTERFACE` > /dev/null 2>&1
        retval=$?
    
        if [ $1 != 0 ]; then

            if [ $retval = 0 ]; then
                echo $MSG_SUCCES_ON_ADD
            else
                FLAG_ROUTE_ADDED=1
                INTERFACE_LIST=`eval $CMD_GET_INTERFACE`
                for SINGLE_INTERFACE in $INTERFACE_LIST
                 do
                      $CMD_ADD_ROUTE $SINGLE_INTERFACE > /dev/null 2>&1
                      retval=$?
                      if [ $1 != 0 ]; then
                         if [ $retval = 0 ]; then
                             FLAG_ROUTE_ADDED=$retval
                         fi
                      fi
                 done
                 if [ $FLAG_ROUTE_ADDED = 0 ]; then
                         echo $MSG_SUCCES_ON_ADD
                         retval=$FLAG_ROUTE_ADDED
                 fi
            fi
        fi

    else
        if [ $1 != 0 ]; then
            echo -n $MSG_SUCCESS_ON_FIND
        fi
        retval=0
    fi

    return $retval
}

SBINDIR=/opt/netatalk/sbin
NAME=slpd
DAEMON=$SBINDIR/$NAME  
SUSE=0

#
# kill the named process(es)
#
killproc() {
	echo "Killing $1..."
	pid=`/bin/ps -e |
	     /bin/grep $1 |
	     /bin/sed -e 's/^  *//' -e 's/ .*//'`
	[ "$pid" != "" ] && kill $pid
}

#
# status of the named process(es)
#
status() {
	pid=`/bin/ps -e |
	     /bin/grep $1 |
	     /bin/sed -e 's/^  *//' -e 's/ .*//'`
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
  LOCK=/var/lock/subsys/slpd
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
    echo -n 'Starting slpd: '

    multicast_route_set 1
    multicast_enabled=$?
    if [ "$multicast_enabled" != "0" ] ; then
      echo "Failure: No Route Available for Multicast Traffic"
      exit 1
    fi
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
    echo -n 'Stopping slpd: '
    
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
    status $SBINDIR/slpd
    RETVAL=$?
    ;;
  *)
    echo "Usage: /etc/rc.d/init.d/slpd {start|stop|restart|reload|status}"
    exit 1
esac

exit $RETVAL
