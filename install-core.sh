#!/bin/bash

# Define those variables to configure CoreOS server
# cloud-config file is below

CHANNEL=stable                                 # channel of Coreos : stable / beta / alpha
TOKEN=<EDITME>                                # token of CoreOS server, goto https://discovery.etcd.io/new?size=3
VM=core                                     # hostname of CoreOS server
VM_USER=user                                  # username of CoreOS server
DC=FR-SD3                                     # datacenter : LU-BI1 / US-BA1 / FR-SD2
DISK=coreosdata                               # diskname of CoreOS server
DS=10G                                        # disksize of CoreOS server

echo -e "CoreOS installation script on Gandi IaaS server \b
Creation of a temporary server with Debian images plus a target disk for CoreOS install"
gandi vm create --datacenter $DC --memory 1024 --cores 1 --ip-version 4  --hostname $VM --image 'Debian 8' --login $VM_USER --password --sshkey $HOME/.ssh/id_rsa.pub
wait
gandi disk create --name $DISK --size $DS --datacenter $DC --vm $VM
sleep 30

echo -e "Get IP of temp VM and check if ssh-key is known, if so delete it"
IP=`gandi vm info $VM | grep ip4 | sed 's/ip4 *: //g'`
wait
ssh-keygen -f $HOME/.ssh/known_hosts -R $IP
wait
ssh-keyscan -H $IP >> $HOME/.ssh/known_hosts
wait

echo -e "Download of Gandi Server settings"
scp root@$IP:/gandi/config ./config
wait

echo -e "Define route, hashed_password, ssh_key, and DNS for cloud-config"
function parse_config {
  local rslt=$(cat config | \
    python -c "import sys,json;data=json.loads(sys.stdin.read());print $1;")
  echo "$rslt"
}

ROUTE=$(parse_config 'data["vif"][0]["pna"][0]["pbn"]["pbn_gateway"]')
PASS=$(parse_config 'data["vm_conf"]["password"]')
SSH=$(parse_config 'data["vm_conf"]["ssh_key"]')
DNS=$(parse_config 'data["nameservers"][1]')
wait

echo -e "Creation of cloud-config"
printf "#cloud-config

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
      - $SSH\n" > cloud-config.yaml
wait

echo -e "Upload of cloud-config"
scp cloud-config.yaml root@$IP:/root/
wait

echo -e "Unmount data disk, Install wget  \b
Download coreos-install script \b
Installation of coreos with cloud-config file"
gandi vm ssh $VM "umount /dev/xvdb;\

apt-get update && apt-get install -y gawk wget &&\

wget https://raw.github.com/coreos/init/master/bin/coreos-install -O coreos &&\

sed '459iumount "${DEVICE}1" && umount "${DEVICE}6" && umount "${DEVICE}9"' coreos > coreos-install

chmod +x coreos-install &&\

./coreos-install -d /dev/xvdb -C $CHANNEL -c cloud-config.yaml &&\

exit"
wait

echo -e "Stop VM and detach both disks"
gandi vm stop $VM && gandi disk detach -f sys_$VM && gandi disk detach -f $DISK
wait

echo -e "Updating kernel to raw on CoreOS disk \b
Attaching CoreOS disk in first position \b
Deleting Debian temp disk !"
gandi disk update --kernel raw $DISK && gandi disk attach -f -p 0 $DISK $VM && gandi disk delete -f sys_$VM
wait

echo -e "Starting CoreOS Server !"
gandi vm start $VM
wait

echo -e "Removing ssh fingerprint"
ssh-keygen -f $HOME/.ssh/known_hosts -R $IP
wait
ssh-keyscan -H $IP >> $HOME/.ssh/known_hosts
wait

echo -e "Login to CoreOS..."
gandi vm ssh --login $VM_USER $VM
