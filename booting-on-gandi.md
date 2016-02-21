# Running CoreOS on Gandi

These instructions will walk you through running CoreOS on Gandi IaaS Server.

## Requirements

To install CoreOS at Gandi, there's a script that simplify the creation and configuration of the CoreOS Server.

That script require [Gandi.cli](https://github.com/gandi/gandi.cli#installation). 

Information on the script and detailled process can be found at [Github](https://github.com/azediv/gnadi-coreos).

When gandi.cli is installed and configured with credits, download and make executable the script.

```sh
wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/install-core.sh && chmod +x install-core.sh
```

## Choosing a Channel

CoreOS is released into stable, alpha and beta channels. Releases to each channel
serve as a release-candidate for the next channel. For example, a bug-free alpha
release is promoted bit-for-bit to the beta channel.

### Edit install-core.sh

Channel and Token are define inside the script. You can also define : hostname, username, datacenter, diskname and disksize. Open `install-core.sh` with your favorite $EDITOR : 

```sh
CHANNEL=alpha                                 # channel of Coreos : stable / beta / alpha
TOKEN=<EDITME>                                # token of CoreOS server, goto https://discovery.etcd.io/new?size=3
VM=coreos                                     # hostname of CoreOS server
VM_USER=user                                  # username of CoreOS server
DC=US-BA1                                     # datacenter : LU-BI1 / US-BA1 / FR-SD2
DISK=coreosdisk                               # diskname of CoreOS server
DS=10G                                        # disksize of CoreOS server
```

While those value are changed, keep $EDITOR open for next section.

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on
startup and more via [cloud-config][cloud-config].  
We're going to provide `cloud-config.yaml` inside the script. Edit to configure as you wish.


```yaml
#cloud-config
coreos:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/$TOKEN
    advertise-client-urls: http://$IP:2379,http://$IP:4001
    initial-advertise-peer-urls: http://$IP:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$IP:2380
  units:
    - name: systemd-networkd.service
      command: stop
    - name: 00-eth0.network
      runtime: true
      content: |
        [Match]
        Name=eth0
        [Network]
        DNS=$DNS
        Address=$IP
        Gateway=$ROUTE
    - name: systemd-networkd.service
      command: start
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
    - name: flanneld.service
      command: start
hostname: $VM
users:
  - name: $VM_USER
    passwd: $PASS
    groups:
      - sudo
    ssh_authorized_keys:
      - $SSH
```

## Start Installation :

When edition is done, start the script :

```sh
./install-core.sh
```

It will ask for password then will log you in as soon as the CoreOS Server is ready (approx 5 min).

## Using CoreOS

Now that you have instances booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).