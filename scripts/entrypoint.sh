#!/bin/sh

cat <<EOF
################################################################################
Welcome to the NetatalkCC
################################################################################
EOF

export IFS=$'\n'

INITALIZED="/.initialized"

if [ ! -f "$INITALIZED" ];
then
  echo ">> CONTAINER: initializing..."
  
  PREFIX=/opt/netatalk
  ETCDIR=$PREFIX/etc
  CONFDIR=$ETCDIR/netatalk
  
  ##
  # TIMEZONE
  ##
  if [ -n "${TIMEZONE}" ];
  then
	ln -sv "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
	echo "${TIMEZONE}" >  /etc/timezone
  fi
	
  ##
  # ATALK ZONE
  ##
  if [ -n "${ATALKZONE}" ];
  then
	  echo "Setting appletalk zone to ${ATALKZONE}"
	  sed -i 's|#ATALK_ZONE=@zone|ATALK_ZONE='"${ATALKZONE}"'|g' "$CONFDIR/netatalk.conf"
  fi

  ##
  # GROUPS
  ##
  for I_CONF in $(env | grep '^GROUP_')
  do
    GROUP_NAME=$(echo "$I_CONF" | sed 's/^GROUP_//g' | sed 's/=.*//g')
    GROUP_ID=$(echo "$I_CONF" | sed 's/^[^=]*=//g')
    echo ">> GROUP: adding group $GROUP_NAME with GID: $GROUP_ID"
    addgroup -g "$GROUP_ID" "$GROUP_NAME"
  done

  ##
  # USER ACCOUNTS
  ##
  for I_ACCOUNT in $(env | grep '^ACCOUNT_')
  do
	echo "Processing account $I_ACCOUNT"
    ACCOUNT_NAME=$(echo $I_ACCOUNT | sed 's/^[^=]*=//g')
    ACCOUNT_PASSWORD=$(env | grep '^PASSWORD_'"$ACCOUNT_NAME" | sed 's/^[^=]*=//g')
	ACCOUNT_AFPPASSWORD=$(env | grep '^AFPPASSWD_'"$ACCOUNT_NAME" | sed 's/^[^=]*=//g')

    ACCOUNT_UID=$(env | grep '^UID_'"$ACCOUNT_NAME" | sed 's/^[^=]*=//g')
    ACCOUNT_PRIMARY_GROUP=$(env | grep '^PRIMARY_GROUP_'"$ACCOUNT_NAME" | sed 's/^[^=]*=//g')
	
    if [ "$ACCOUNT_UID" -gt 0 ] 2>/dev/null
    then
      ACCOUNT_UID_PARAM="-u $ACCOUNT_UID"
    fi
    if [ -n "$ACCOUNT_PRIMARY_GROUP" ] 2>/dev/null
    then
      ACCOUNT_GID_PARAM="-G $ACCOUNT_PRIMARY_GROUP"
    fi
    echo "eval adduser -D -H $ACCOUNT_UID_PARAM $ACCOUNT_GID_PARAM -s /sbin/nologin $ACCOUNT_NAME"
    eval adduser -D -H $ACCOUNT_UID_PARAM $ACCOUNT_GID_PARAM -s /sbin/nologin "$ACCOUNT_NAME"
	
	echo -e "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | passwd "$ACCOUNT_NAME"
	if [ -n "${ACCOUNT_AFPPASSWORD}" ];
	then
		echo "$ACCOUNT_AFPPASSWORD" >> "${CONFDIR}/afppasswd"
		#echo -e "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | afppasswd -a "$ACCOUNT_NAME"
	fi

    # add user to groups...
    ACCOUNT_GROUPS=$(env | grep '^GROUPS_'"$ACCOUNT_NAME" | sed 's/^[^=]*=//g')
    for GRP in $(echo "$ACCOUNT_GROUPS" | tr ',' '\n' | grep .);
	do
      echo ">> ACCOUNT: adding account: $ACCOUNT_NAME to group: $GRP"
      addgroup "$ACCOUNT_NAME" "$GRP"
    done
    unset $(echo "$I_ACCOUNT" | cut -d'=' -f1)
  done

  ##
  # Appletalk interfaces, atalkd
  ##
  for I_INTERFACE in $(env | grep '^ATALKD_INTERFACE_')
  do
	echo "Processing Appletalk interface $I_INTERFACE"
    INTERFACE_CONFIG=$(echo $I_INTERFACE | sed 's/^[^=]*=//g')
    echo "$INTERFACE_CONFIG" >> "$CONFDIR/atalkd.conf"
  done

  ##
  # AFP instances, afpd
  ##
  for I_INSTANCE in $(env | grep '^AFPD_INSTANCE_')
  do
	echo "Processing AFP instance $I_INSTANCE"
    INSTANCE_CONFIG=$(echo $I_INSTANCE | sed 's/^[^=]*=//g')
    echo "$INSTANCE_CONFIG" >> "$CONFDIR/afpd.conf"
  done

  ##
  # Shares default config (Volumes)
  ##
  echo "Setting volume default options $VOLUME_DEFAULT_OPTIONS"
  sed -i 's|:DEFAULT: options:upriv,usedots|'"$VOLUME_DEFAULT_OPTIONS"'|g' "$CONFDIR/AppleVolumes.default"

  ##
  # Shares (Volumes)
  ##
  for I_SHARE in $(env | grep '^SHARE_')
  do
	echo "Processing share $I_SHARE"
    SHARE_CONFIG=$(echo $I_SHARE | sed 's/^[^=]*=//g')
    echo "$SHARE_CONFIG" >> "$CONFDIR/AppleVolumes.default"
  done

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
