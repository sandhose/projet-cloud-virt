{% set comma = joiner(", ") %}
{% for student in item.students|default([]) %}{{ comma() }}{{ student }}{% endfor %}


[Cloud-Virt] Vos identifiants pour le groupe "{{ item.name }}"

Trois machines virtuelles vous ont été affectée pour le projet de Cloud et Virtualisaiton.
Ces machines sont accessibles par SSH :

{% for member in item.members %}
    ssh -J student@bastion.100do.se ubuntu@{{ member }}.internal.100do.se
{% endfor %}

Clé SSH privée pour accéder à vos machines :

{{ lookup('file', 'instructions/per-group/' + item.name + '/id_ecdsa') }}

Pour simplifier la connexion par SSH, ajoutez cette section à votre fichier ~/.ssh/config:

    Host bastion-cloud
      Hostname bastion.100do.se
      User student
{% for member in item.members %}

    Host {{ member }}
      Hostname {{ member }}.internal.100do.se
      User ubuntu
      ProxyJump bastion-cloud
{% endfor %}

Vous pourrez ensuite vous connecter à vous machines via :

{% for member in item.members %}
    ssh {{ member }}
{% endfor %}

IP interne utilisée par Consul et Nomad : {{ item.network | ansible.utils.ipaddr('120') | ansible.utils.ipaddr('address') }}
Console Nomad : https://{{ item.name }}.nomad.100do.se/
Console Consul : https://{{ item.name }}.consul.100do.se/

Un bucket S3 a été provisionné pour vous :
    Serveur : https://s3.100do.se/
    Console : https://s3-console.100do.se/
    Access Key ID : {{ item.name }}
    Secret Access Key : {{ lookup("password", "./instructions/per-group/" + item.name + "/minio", chars=["ascii_letters", "digits"]) }}

Un accès à RabbitMQ a été provisionné pour vous :
    URL : amqp://queue.internal.100do.se:5672/{{ item.name }}
    Console : https://queue.100do.se/
    Username : {{ item.name }}
    Password : {{ lookup("password", "./instructions/per-group/" + item.name + "/queue", chars=["ascii_letters", "digits"]) }}

IP flottante: {{ item.network | ansible.utils.ipaddr('110') | ansible.utils.ipaddr('address') }}

Proxy HTTPS vers l'IP flottante: https://{{ item.name }}.100do.se/ et https://nimporte-quoi-{{ item.name }}.100do.se/

En supposant que `nomad` et `consul` sont installés sur la machines que vous utilisez, vérifiez que vous arrivez à vous connecter à votre instance de Nomad et Consul:

    export CONSUL_HTTP_ADDR=https://{{ item.name }}.consul.100do.se
    export NOMAD_ADDR=https://{{ item.name }}.nomad.100do.se
    consul members
    nomad server members

Liste des proxy HTTPS:

    https://{{ item.name }}.consul.100do.se -> http://{{ item.network | ansible.utils.ipaddr('120') | ansible.utils.ipaddr('address') }}:8500
    https://{{ item.name }}.nomad.100do.se -> http://{{ item.network | ansible.utils.ipaddr('120') | ansible.utils.ipaddr('address') }}:4646
    https://{{ item.name }}.100do.se -> http://{{ item.network | ansible.utils.ipaddr('110') | ansible.utils.ipaddr('address') }}:8081
    https://*{{ item.name }}.100do.se -> http://{{ item.network | ansible.utils.ipaddr('110') | ansible.utils.ipaddr('address') }}:8081
{% for member in item.members %}
    https://{{ member }}.100do.se -> http://{{ item.network | ansible.utils.ipaddr(hostvars[member].host_index) | ansible.utils.ipaddr('address') }}:8080
    https://*{{ member }}.100do.se -> http://{{ item.network | ansible.utils.ipaddr(hostvars[member].host_index) | ansible.utils.ipaddr('address') }}:8080
{% endfor %}
