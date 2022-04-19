# Contexte

Ce projet a pour but de déployer une application fournie de la manière la plus automatisée et résiliante possible.
L'application permet à ses utilisateurs d'héberger des images, en les redimensionnant au passage dans différentes tailles.
Le projet est à réaliser en binôme.

# Détails de l'application

L'application comporte de trois composants :

 - un *backend* se chargant de sauvegarder les images téléversées, ainsi que de servir les images hébergées
 - un *worker* se chargant de redimensionner les images téléversées dans différentes tailles
 - un *frontend*, sous la forme d'une interface web, pour permettre aux utilisateurs d'envoyer les images

Les images sont stockées dans un espace de stockage compatible S3.

Le backend utilise la bibliothèque Python [*Celery*](https://docs.celeryq.dev/en/stable/) pour envoyer des tâches à exécuter au *worker* via une file de message.

Tous ces composants sont *scalables* horizontalement : plusieurs instances du *backend*, du *worker* ou du *frontend* peuvent cohéxister et se partager la charge.

Le code de l'application est disponible à ces trois adresses (pour simplifier le *fork* du dépôt) : 

 - <https://github.com/sandhose/projet-cloud-virt>
 - <https://git.unistra.fr/qgliech/projet-cloud-virt>
 - <https://gitlab.com/sandhose/projet-cloud-virt>

Vous trouverez dans ce dépôt :

 - le code du *backend* et du *worker* dans le sous-dossier `api/`
 - le code du *frontend* dans le sous-dossier `web/`
 - ce sujet dans le sous-dossier `sujet/`
 - (pour information) le *playbook* [Ansible](https://docs.ansible.com/ansible/latest/index.html) utilisé pour provisionner l'infrastructure de votre fournisseur *Cloud* dans le sous-dossier `playbook/`

Chacun de ces sous-dossier a un fichier `README.md` expliquant certains détails de leur fonctionnement.

# Détails de l'infrastructure

Votre fournisseur *Cloud* vous fournit, pour chaque binôme : 

 - du stockage type S3
 - une file de message [RabbitMQ](https://www.rabbitmq.com)
 - un serveur [Consul](https://www.consul.io)
 - un serveur [Nomad](https://www.nomadproject.io)
 - deux machines virtuelles
 - une IP flottante
 - des tunnels HTTP vers vos machines virtuelles et votre IP flottante

## Connexion aux machines virtuelles

Les machines virtuelles sont accessibles par SSH via un hôte bastion, accessible depuis le réseau de l'université, donc connecté au wifi de l'université ou via le VPN : <https://documentation.unistra.fr/Catalogue/Infrastructures-reseau/osiris/VPN/co/guide.html>

Le bastion est accessible par SSH à `student@185.155.93.175`.
Vous devriez pouvoir accéder à votre machine virtuelle par SSH de cette manière :

```sh
ssh -J student@185.155.93.175 ubuntu@192.168.70.XXX
```

Pour simplifier l'accès, vous pouvez ajouter à votre fichier de configuration SSH (`~/.ssh/config`) la section suivante:

```sshconfig
Host bastion-cloud
	Hostname 185.155.93.175
	User student

Host <nom-de-la-vm-1>
	Hostname 192.168.70.<vm-1>
	User ubuntu
	ProxyJump bastion-cloud

Host <nom-de-la-vm-2>
	Hostname 192.168.70.<vm-2>
	User ubuntu
	ProxyJump bastion-cloud
```

Par exemple, si vous avez les machines virtuelles `eager-franklin` et `awesome-boyd` :

```sshconfig
Host bastion-cloud
	Hostname 185.155.93.175
	User student

Host eager-franklin
	Hostname 192.168.70.100
	User ubuntu
	ProxyJump bastion-cloud

Host awesome-boyd
	Hostname 192.168.70.101
	User ubuntu
	ProxyJump bastion-cloud
```

Puis, vous pourrez directement accéder à vos machines virtuelles via `ssh <nom de la machine>`.

Les informations de connexion vous ont été envoyées individuellement par mail.

## Réseau des machines virtuelles

Il existe sur toutes les machines virtuelles un tunnel VXLAN offrant un réseau privé au niveau 2 entre elles.
Vous trouverez la définition de ce tunnel (interface `vxlan100`) dans le dossier `/etc/systemd/network/`.

Chaque machine virtuelle a une IP dans ce réseau (`172.16.1.X/16`).
Chaque groupe dispose d'une IP flottante qui peut être assignée dynamiquement à l'une de vos machine virtuelle (`172.16.3.X/16`).

Pour assigner l'IP virtuelle, vous pouvez simplement l'ajouter à l'interface (`ip address add dev vxlan100 172.16.3.X/16`), ou utiliser un outil tel que [`keepalived`](https://www.redhat.com/sysadmin/keepalived-basics) pour l'ajouter dynamiquement à l'une des machine virtuelle.

**Attention :** cette interface n'a pas la route par défaut.
Consul et Nomad par défaut annoncent l'IP de l'interface où se trouve la route par défaut, donc assurez vous qu'ils annoncent l'IP de l'interface `vxlan100` lorsque vous les configurerez.

## Tunnels HTTP(S)

Votre fournisseur de *Cloud* a mis en place des proxy HTTP(S) vers votre IP flottante et vos machines virtuelles.

Ainsi :

 - `https://<vm>.100do.se/` et `http://*.<vm>.100do.se/` transmet le traffic vers l'IP de la machine virtuelle sur le port `8080`.
   Par exemple, `https://eager-franklin.100do.se/` proxy vers `http://172.16.1.0:8080/`.
 - `https://<groupe>.100do.se/` et `http://*.<groupe>.100do.se/` transmet le traffic vers l'IP flottante du groupe sur le port `8081`.
   Par exemple, `https://gracious-raman.100do.se/` proxy vers `http://172.16.3.0:8081/`.

## File de message

Votre fournisseur *Cloud* vous donne accès à une instance de RabbitMQ, une file de message.
Son interface web est accessible sur <https://queue.100do.se>.
Cette instance est commune à tous les groupes, mais chaque groupe a accès à un *virtual host* isolé du reste.

En interne, la file est accessible via le protocole AMQP :

```
amqp://<username>:<password>@awesome-boyd.internal.100do.se:5672/<vhost>
```

où `<username>` et `<password>` sont les identifiants fournis par votre fournisseur cloud, et `<vhost>` est le nom assigné à votre binôme.

## Stockage S3

Votre fournisseur *Cloud* vous donne accès à une instance de [Minio](http://min.io), un service de stockage compatible S3.
Il est accessible sur <https://s3.100do.se>.
Cette instance est commune à tous les groupes, mais chaque groupe a accès à plusieurs *buckets*.

Chaque groupe a une paire d'identifiants (*access key id* et *secret access key*) ayant accès à leurs *buckets*.

## Consul et Nomad

Votre fournisseur *Cloud* héberge pour chaque binôme un *cluster* [Consul](https://learn.hashicorp.com/tutorials/consul/get-started?in=consul/getting-started#architecture-overview) et un *cluster* [Nomad](https://learn.hashicorp.com/tutorials/nomad/get-started-intro?in=nomad/get-started).

Ils sont accessibles sous :

 - `https://consul-<groupe>.100do.se/` pour Consul
 - `https://nomad-<groupe>.100do.se/` pour Nomad

En interne, ils sont accessibles via le nom d'hôte `<groupe>.internal.100do.se`.

Ces clusters n'ont pas de client.
Autrement dit, ils ne vous permettent pas tels quels d'exécuter des *jobs* Nomad.
Votre but est de configurer sur chacune de vos machines virtuelles l'agent Consul et le client Nomad, et de les faire rejoindre le *cluster*.

Sur vos machines virtuelles, Nomad et Consul sont installés, mais pas configurés.

Consul lit sa configuration dans `/etc/consul.d/consul.hcl`.
Il stocke ses données (option `-data-dir`) dans `/opt/consul`.
Vous pouvez le démarrer via `systemctl start consul.service`.
La définition du service se trouve dans `/etc/systemd/service/consul.service`.

Nomad lit sa configuration dans `/etc/nomad.d/nomad.hcl`.
Il stocke ses données (option `-data-dir`) dans `/opt/nomad`.
Vous pouvez le démarrer via `systemctl start nomad.service`.
La définition du service se trouve dans `/etc/systemd/service/nomad.service`.

**Attention à la configuration réseau de Nomad et Consul !**
Par défaut, ces deux services annoncent auprès du *cluster* l'IP de l'interface réseau ayant la route par défaut.
Dans votre cas, vous **devez** les configurer pour qu'ils annoncent l'adresse de l'interface `vxlan100`.

## Registre d'images de conteneurs

Votre fournisseur *Cloud* ne fournit malheuresement pas de registre d'image de conteneurs.
Vous pouvez cependant vous tourner vers des options gratuites telles que :

 - Docker Hub : <https://hub.docker.com/>
 - GitHub Container Registry : <https://ghcr.io/>
 - GitLab.com : <https://gitlab.com/>
 - Quay.io : <https://quay.io>

# Modalité de rendu et critères d'évaluation

Le projet est volontairement libre sur la manière de déployer cette application.
Par exemple, vous n'êtes pas obligés d'utiliser Nomad ou même Docker pour tous les composants de votre déploiement.

Vous expliquerez dans **un rapport** le fonctionnement de votre déploiement, et justifirez vos choix.
Vous deverez notamment expliquer :

 - comment se passerait le déploiement d'une nouvelle version de l'application ;
 - la procédure pour effectuer une maintenance planifiée d'un nœud (par exemple : redémarrage suite à une mise à jour du système) ;
 - les étapes pour ajouter ou supprimer un nœud de votre infrastructure ;
 - l'impact de différents scénarios de panne ;
 - tout ce qui vous paraît pertinent à savoir pour quelqu'un qui devrait ensuite maintenir cette infrastructure à votre place.

Vous serez évalués entre autre sur :

 - vos images Docker, si vous en utilisez ;
 - la lisibilité de vos scripts et fichiers de configuration ;
 - le niveau général d'automatisation ;
 - la résilience de votre déploiement ;
 - la pertinence de vos choix techniques.

En plus du rapport, vous fournirez **un dépôt Git** contenant vos scripts et fichiers de configurations, ainsi que le code de l'application si vous l'avez modifié.
