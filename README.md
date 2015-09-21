# gnadi-coreos
Script d'installation de CoreOS sur une VM Gandi avec gandi.cli

## source
"fork" d'un script de jmbarbier : 
https://gist.github.com/jmbarbier/ab06cf23735845a0167a

## pré-requis 
 - gandi.cli

## if-core-config.sh
if-core-config.sh est utilisé sur la VM  pour récupérer la configuration réseau de l'interface.

L'adresse IP le DNS et la route sont ajoutés au fichier cloud-config.yml

## core-install.sh
core-install.sh est utilisé sur l'ordinateur local pour initier le processus automatisé d'install

## coreos.md
Processus détaillé étape par étape de l'installation de CoreOS sur une VM avec gandi.cli
