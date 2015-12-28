#!/bin/bash

echo -e "\b
===================================================== \b
== CoreOS installation script on Gandi IaaS server == \b
===================================================== \b
\b
Requirements : \b
\b
 * gandi.cli configured with IaaS credit : http://cli.gandi.net \b

\b"

# Define those variables to configure CoreOS server

# Hostname for CoreOS
VM=vmcore

# User for coreos
VM_USER=usercore

# Datacenter
DC=US

# Disk Name
DISK=diskcore

#Disk Size can be M G or T
DS=10G

# Create temp vm to attach data disk as target of coreos install script

echo -e "\b
===================================================== \b
= Creation of a temporary server with Debian images = \b
===================================================== \b
"

gandi vm create --datacenter $DC --memory 512 --cores 1 --ip-version 4  --hostname $VM --image 'Debian 8 64 bits (HVM)' --login $VM_USER --password --sshkey $HOME/.ssh/id_rsa.pub

wait

echo -e "
Success !\b
"

# Create data disk to attach to vm

echo -e "
===================================================== \b
=== Creation of a target disk for CoreOS install ==== \b
===================================================== \b
"

gandi disk create --name $DISK --size $DS --datacenter $DC --vm $VM

sleep 30

echo -e "
Success ! \b
"

# Get vm IP

echo -e "
===================================================== \b
=================== Get IP of VM ==================== \b
===================================================== \b
"

IP=`gandi vm info $VM | grep ip4 | sed 's/ip4 *: //g'`

wait

echo -e "
Success ! \b
"

# Remove fingerprint if IP already known

echo -e "
===================================================== \b
=== Check if ssh-key is known and if so delete it  == \b
===================================================== \b

"

ssh-keygen -f $HOME/.ssh/known_hosts -R $IP

# Download of gandi config file containing all informations about vm

echo -e "
Success ! \b
"

echo -e "
===================================================== \b
=========== Download of Gandi config ================ \b
===================================================== \b
"

scp root@$IP:/gandi/config ./config

wait

echo -e "
Success ! \b
"

# Define from gandi config file : route, hashed password, ssh key, dns

echo -e "
===================================================== \b
= Define Route Password SSH and DNS for cloud-config= \b
===================================================== \b
"

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

echo -e "
Success ! \b
"

# Creation of cloud-config.yml file

echo -e "
===================================================== \b
========== Creation of cloud-config ================= \b
===================================================== \b
"

printf "#cloud-config
coreos:
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
hostname: $VM
users:
  - name: $VM_USER
    passwd: $PASS
    groups:
      - sudo

    ssh_authorized_keys:
      - $SSH\n" > cloud-config.yml

wait

echo -e "
Success ! \b
"

echo -e "
===================================================== \b
=========== Edition of cloud-config ================= \b
===================================================== \b
"

echo -e "
===================================================== \b
=========== Default cloud-config.yml ================ \b
===================================================== \b
"

cat cloud-config.yml

echo -e "
===================================================== \b
===== Do you wish to edit cloud-config.yml ? ======== \b
=======           Type [1] or [2] :          ======== \b
===================================================== \b
"

select yn in "yes" "no"; do
    case $yn in
        yes ) nano cloud-config.yml; break;;
        no ) echo continue installation; break;;
        *) echo invalid option;;
    esac
done

echo "
edition done, this file will now be used to install CoreOS :
"

echo -e "
===================================================== \b
=============== New cloud-config.yml ================ \b
===================================================== \b
"

cat cloud-config.yml

# Upload of cloud-config.yml file

echo -e "
===================================================== \b
============== Upload of cloud-config =============== \b
===================================================== \b
"

scp cloud-config.yml root@$IP:/root/

wait

echo -e "
Success ! \b
"


# Unmount of data disk  before installation of CoreOS
# Install of wget
# Download  of coreos-install script
# Installation of coreos from cloud-config file

echo -e "
===================================================== \b
================ Unmount data disk ================== \b
==================== Install wget =================== \b
======= Download  of coreos-install script ========== \b
==== Installation of coreos from cloud-config file == \b
===================================================== \b
"

gandi vm ssh $VM "umount /dev/sdc;\

apt-get update && apt-get install -y wget &&\

wget https://raw.github.com/coreos/init/master/bin/coreos-install &&\

chmod +x coreos-install &&\

./coreos-install -d /dev/sdc -C alpha -c cloud-config.yml &&\

exit"

wait

echo -e "
Success ! \b
"

# Stop of vm before detaching disks

echo -e "
===================================================== \b
======= Stop VM before detaching both disks ========= \b
===================================================== \b

"

gandi vm stop $VM

wait

echo -e "
Success ! \b
"

# Detach both disk

echo -e "
===================================================== \b
============== Detaching both disks ================= \b
===================================================== \b
"

gandi disk detach -f sys_$VM

wait

gandi disk detach -f $DISK

wait

echo -e "
Success ! \b
"

# Update kernel of CoreOS disk as raw

echo -e "
===================================================== \b
====== Updating kernel to raw on CoreOS disk ======== \b
===================================================== \b
"

gandi disk update --kernel raw $DISK

wait

echo -e "
Success ! \b
"

# Attach CoreOS disk in first position

echo -e "
===================================================== \b
====== Attach CoreOS disk in first position ========= \b
===================================================== \b
"

gandi disk attach -f -p 0 $DISK $VM

wait

echo -e "
Success ! \b
"

# Delete Debian disk

echo -e "
===================================================== \b
=========== Deleting Debian temp disk ! ============= \b
===================================================== \b
"

gandi disk delete -f sys_$VM

wait

echo -e "
Success ! \b
"

# Start CoreOS vm

echo -e "
===================================================== \b
============== Starting CoreOS Server ! ============= \b
===================================================== \b
"

gandi vm start $VM

wait

echo -e "
Success ! \b
"

# Remove previous ssh fingerprint

echo -e "
===================================================== \b
============= Removing ssh fingerprint ============== \b
===================================================== \b
"

ssh-keygen -f $HOME/.ssh/known_hosts -R $IP

echo -e "
Success ! \b
"

echo -e "
===================================================== \b
=============== Login to CoreOS... ================== \b
===================================================== \b
"

# Connect via SSH to CoreOS new vm

gandi vm ssh --wait --login $VM_USER $VM


