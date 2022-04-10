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

DSM -> Docker -> Image -> Hinzufügen -> Aus Datei hinzufügen (Upload netatalk_classic.tar from step 1)


4. Adjust configuration in NetatalkCC.json

TODO!!!!


5. Create container based on SambaCC.json

DSM -> Container -> Einstellungen -> Importieren (Upload NetatalkCC.json)
Select Container -> Aktion -> Start

Connect to your share from a classic Mac

