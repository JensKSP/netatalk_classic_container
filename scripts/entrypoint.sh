#!/bin/sh

cat <<EOF
################################################################################
Welcome to the NetatalkCC
################################################################################
EOF

INITALIZED="/.initialized"

if [ ! -f "$INITALIZED" ]; then

	# TODO: The whole configuration process of 
	# appletalk interfaces, shares, users, signature, etc...

	# TODO
	NICS=
	# TODO
	SHARES=
	# TODO
	SIGNATURE=

	# TODO 
	USER=bridge
	UID=1027
	GID=100
	PASSWD_LINE="bridge:2177416C6B657231:****************:********"
	
	##
	# USER ACCOUNTS
	##
	for I_ACCOUNT in $(env | grep '^ACCOUNT_')
	done
	

	/bin/id $USER 2>/dev/null
	if ! [ $? -eq 0 ];
	then
		echo "Creating user $USER..."
		useradd -u $UID -g $GID $USER
		# afppasswd -a $USER
		echo $PASSWD_LINE \
			>> /opt/netatalk/etc/netatalk/afppasswd
	fi
	
	touch "$INITALIZED"
else
  echo ">> CONTAINER: already initialized - direct start of netatalk"
fi

##
# CMD
##
echo ">> CMD: exec docker CMD"
echo "$@"
exec "$@"
