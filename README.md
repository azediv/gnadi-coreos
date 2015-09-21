# gnadi-coreos
bash script to create a CoreOS vm with gandi.cli

## pré-requis 
gandi.cli

## if-core-config.sh
if-core-config.sh est utilisé sur la VM  pour récupérer la configuration réseau de l'interface.

L'adresse IP le DNS et la route sont ajoutés au fichier cloud-config.yml

## core-install.sh
core-install.sh est utilisé sur l'ordinateur local pour initier le processus automatisé d'install

## coreos.md
Processus détaillé étape par étape de l'installation de CoreOS sur une VM avec gandi.cli
