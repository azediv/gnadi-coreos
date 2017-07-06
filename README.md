# CoreOS on Gandi IaaS
Installation of CoreOS on Gandi server with gandi.cli, Automatic and Manual.

### Original idea
"fork" from jmbarbier's idea to create a cluster of CoreOS on Gandi vm : 
https://gist.github.com/jmbarbier/ab06cf23735845a0167a


### Requirements
 - gandi.cli setup with credits on iaas account
 - ssh keys  on local computer
 - the force luke

# Howto 

## Automatic script

install-core.sh is used on your local computer in combination with gandi.cli to create a temporary vm and a target disk to install coreos. cloud-config.yaml is created with /gandi/config json file.

### Download on local computer and make it executable : 

	wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/install-core.sh && chmod +x install-core.sh


### Setup script
#### Edit install-core.sh :
	vim install-core.sh

#### to change :
	  - $CHANNEL
	  - $TOKEN
	  - $VM  (hostname)
	  - $VM_USER (username)
	  - $DC (datacenter)
	  - $DISK (coreos system disk name)
	  - $DS (coreos system disk size)
	
### Run :

	./install-core.sh

## Manual process

### Resume

Creation of a Debian temp vm plus a 10GB data disk as target for CoreOS install.

Get vm config from /gandi/config of temp vm.

Creation of cloud-config.yml file.

Installation of CoreOS from temp vm to data disk.

Stop vm, detach Debian disk, define kernel as raw on CoreOS disk, attach CoreOS disk as system disk to vm.

Boot and enjoy

### Details:
	
	- $ prompt is for commands run on local computer
	- # prompt is for commands run on temp vm

Creation of Debian vm (512Mo at least, 256Mo isn't enough to install packages) :

	$  gandi vm create --datacenter $DC --memory 1024 --cores 1 --ip-version 4  --hostname $VM --image 'Debian 9' --login $VM_USER --password --sshkey $HOME/.ssh/id_rsa.pub

SSH to Debian :

	$ gandi vm ssh $VM

Change CONFIG_ALLOW_MOUNT to 0 :

	# sed -i '/CONFIG_ALLOW_MOUNT=1/c\CONFIG_ALLOW_MOUNT=0' /etc/default/gandi

Creation of data disk (target of CoreOS install) and attachment to VM :

	$ gandi disk create --name core_sys --size 10G --datacenter $DC -vm $VM

Installation of wget

	# apt-get update && apt-get install -y wget gawk

Download of coreos install script :

	# wget https://raw.github.com/coreos/init/master/bin/coreos-install

Define as executable :

	# chmod +x coreos-install

Grab username, hashed password, sshkey of vm from /gandi/config json file : 

	- VM_USER = cat /gandi/config| grep -Po '(?<="user": ")[^"]*' |head -1
	- PASS = cat /gandi/config | grep -Po '(?<="password": ")[^"]*'
	- SSH = cat /gandi/config | grep -Po '(?<="ssh_key": ")[^"]*'

Grab network config of vm from /gandi/config json file : 

	- VM = cat /gandi/config| grep -Po '(?<="vm_hostname": ")[^"]*'
	- IP = cat /gandi/config| grep -Po '(?<="pna_address": ")[^"]*' |head -1
	- ROUTE = cat /gandi/config | grep -Po '(?<="pbn_gateway": ")[^"]*' | head -1
	- DNS = gandi vm ssh $VM 'cat /etc/resolv.conf' | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1

Creation of cloud-config.yml file for CoreOS installation.

Contains static network, user, sshkey, units, etc...

Help : https://coreos.com/os/docs/latest/cloud-config.html#users


	# nano cloud-config.yml


	#cloud-config
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
	      - docker
	      
	    ssh_authorized_keys:
	      - $SSH


Starting CoreOS installation with cloud-config.yml

	# ./coreos-install -d /dev/sdc -C alpha -c cloud-config.yml

When installation is successfull, logout of Debian :

	# exit

Stop the Debian vm :

	$ gandi vm stop $VM

Detach of system disk of Debian Detach of data disk, CoreOS :

	$ gandi disk detach sys_$VM

	$ gandi disk detach core_sys

Update kernel to raw of data disk of CoreOS :

	$ gandi disk update --kernel raw core_sys

Attachment as system disk (-p 0) to vm :

	$ gandi disk attach -p 0 core_sys $VM

First start of CoreOS on Gandi vm ! :

	$ gandi vm start $VM

Remove previous SSH fingerprint for IP  :

	$ ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R $IP

Login to CoreOS :

	$ gandi vm ssh --login $VM_USER $VM

Ping us ! :

	  Container Linux by CoreOS stable (1409.5.0)	
	  $VM_USER@$VM ~ $ ping gandi.net
	  PING gandi.net (217.70.184.1) 56(84) bytes of data.
	  64 bytes from website.vip.gandi.net (217.70.184.1): icmp_seq=1 ttl=60 time=2.24 ms
