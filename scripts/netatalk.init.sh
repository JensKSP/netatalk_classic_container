#! /bin/sh
#
# Start/stop the Netatalk :NETATALK_VERSION: daemons.
#
# If you use AppleTalk, Make sure not to start atalkd in the background:
# its data structures must have time to stablize before running the
# other processes.
#

#
# kill the named process(es)
#
killproc() {
	pid=`/bin/ps -e |
	     /bin/grep $1 |
	     /bin/sed -e 's/^  *//' -e 's/ .*//'`
	[ "$pid" != "" ] && kill $pid
}

# default
ATALK_NAME=`hostname|cut -d. -f1`
ATALK_UNIX_CHARSET='LOCALE'
ATALK_MAC_CHARSET='MAC_ROMAN'

CNID_METAD_RUN=yes
AFPD_RUN=yes
AFPD_MAX_CLIENTS=20
AFPD_UAMLIST="-U uams_dhx.so,uams_dhx2.so"
AFPD_GUEST=nobody
CNID_CONFIG="-l log_info"

ATALKD_RUN=no
PAPD_RUN=no
TIMELORD_RUN=no
A2BOOT_RUN=no
ATALK_ZONE=
ATALK_BGROUND=no

# old netatalk.conf expected hostname in $HOSTNAME by default
HOSTNAME=`hostname`

. /opt/netatalk/etc/netatalk/netatalk.conf


#
# Start the netatalk server processes.
#

atalk_startup() {
	echo 'starting netatalk daemons: \c'
	if [ x"${ATALKD_RUN}" != x"no" ]; then
		if [ -x /opt/netatalk/sbin/atalkd ]; then
			/opt/netatalk/sbin/atalkd;		echo ' atalkd\c'
		fi

		if [ -x /opt/netatalk/bin/nbprgstr ]; then
			/opt/netatalk/bin/nbprgstr -p 4 "${ATALK_NAME}:Workstation${ATALK_ZONE}";
			/opt/netatalk/bin/nbprgstr -p 4 "${ATALK_NAME}:netatalk${ATALK_ZONE}";
							echo ' nbprgstr\c'
		fi

		if [ x"${PAPD_RUN}" = x"yes"  -a -x /opt/netatalk/sbin/papd ]; then
			/opt/netatalk/sbin/papd;			echo ' papd\c'
		fi

		if [ x"${TIMELORD_RUN}" = x"yes"  -a -x /opt/netatalk/sbin/timelord ]; then
			/opt/netatalk/sbin/timelord;		echo ' timelord\c'
		fi

		if [ x"${A2BOOT_RUN}" = x"yes"  -a -x /opt/netatalk/sbin/a2boot ]; then
			/opt/netatalk/sbin/a2boot;		echo ' a2boot\c'
		fi
	fi

	if [ x"${CNID_METAD_RUN}" = x"yes" -a -x /opt/netatalk/sbin/cnid_metad ]; then
        /opt/netatalk/sbin/cnid_metad $CNID_CONFIG
        echo ' cnid_metad\c'
	fi

	if [  x"${AFPD_RUN}" = x"yes" -a -x /opt/netatalk/sbin/afpd ]; then
		/opt/netatalk/sbin/afpd  ${AFPD_UAMLIST} -g ${AFPD_GUEST} \
               -c ${AFPD_MAX_CLIENTS} -n "${ATALK_NAME}${ATALK_ZONE}";	echo ' afpd\c'
	fi

	echo '.'
}


case "$1" in

'start')
        if [ x"${ATALK_BGROUND}" = x"yes" -a x"${ATALKD_RUN}" != x"no" ]; then
            echo "Starting netatalk in the background ... "
            atalk_startup > /dev/null &
        else
            atalk_startup
        fi
        ;;

#
# Stop the netatalk server processes.
#
'stop')

	echo 'stopping netatalk daemons:\c'

	if [ -x /opt/netatalk/sbin/papd ]; then
		killproc papd;			echo ' papd\c'
	fi

	if [ -x /opt/netatalk/sbin/afpd ]; then
		killproc afpd;			echo ' afpd\c'
	fi

	if [ -x /opt/netatalk/sbin/cnid_metad ]; then
		killproc cnid_met;		echo ' cnid_metad\c'
	fi

	if [ -x /opt/netatalk/sbin/timelord ]; then
		killproc timelord;		echo ' timelord\c'
	fi

	if [ -x /opt/netatalk/sbin/a2boot ]; then
		killproc a2boot;		echo ' a2boot\c'
	fi

	# kill atalkd last, since without it the plumbing goes away.
	if [ -x /opt/netatalk/sbin/atalkd ]; then
		killproc atalkd;		echo ' atalkd\c'
	fi

	echo '.'
	;;

#
# Usage statement.
#

*)
	echo "usage: $0 {start|stop}"
	exit 1
	;;
esac
