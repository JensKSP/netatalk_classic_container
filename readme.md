# Synology NAS: Run Netatalk in Docker container to provide network shares for classic Apple machines

1. Build docker image

```
cd NetatalkCC
docker build -t netatalk_classic  .
docker save netatalk_classic -o netatalk_classic.tar
```

2. Setup docker access to avahi (mDNS) (optional)

Some versions of Mac OS X resolve the AFP service using mDNS (Bonjour, Avahi).
To give the docker container access to the avahi-daemon we need to
make /var/run/avai-daemon and /var/run/dbus accessible to the container:

```
mkdir -p /volume1/docker/run
 ln -sv /var/run/avahi-daemon/ /volume1/docker/run/avahi-daemon
 ln -sv /var/run/dbus/ /volume1/docker/run/dbus
```


3. Import docker image to Synology NAS

DSM -> Docker -> Image -> Add -> From File (Upload netatalk_classic.tar from step 1)


4. Adjust configuration in NetatalkCC.json

TODO!!!!


5. Create container based on SambaCC.json

DSM -> Container -> Settings -> Import (Upload NetatalkCC.json)
Select Container -> Action -> Start

Connect to your share from a classic Mac

# Docker env vars

ACCOUNT_bridge="bridge"
PASSWORD_bridge="!wAlker1"
AFPPASSWD_bridge="bridge:2177416C6B657231:****************:********"
UID_bridge=1027
GID_bridge=100
GROUPS_bridge=""
ATALKD_INTERFACE_eth1="eth1 -phase 2 -net 0-65534 -addr 65280.157"
AFPD_INSTANCE_default="- -transall -setuplog \"default log_debug\" -uamlist uams_randnum.so,uams_dhx.so,uams_dhx2.so -maccodepage MAC_CENTRALEUROPE -nouservol -slp"
VOLUME_DEFAULT_OPTIONS=":DEFAULT: options:upriv,usedots"
SHARE_cc="/shares/cc \"cc\" allow:bridge rwlist:bridge perm:0777 dperm:0777 fperm:0666 umask:0000"
