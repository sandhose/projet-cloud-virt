IP de Nomad/Consul: `{{ item.consul_address }}`

IP flottante: `{{ item.floating_address }}`

Nomad: <https://nomad-{{ item.name }}.100do.se>

Consul: <https://consul-{{ item.name }}.100do.se>

IP flottante: <https://{{ item.name }}.100do.se> et <http://nimporte.{{ item.name }}.100do.se>

Test:
```sh
export CONSUL_HTTP_ADDR=https://consul-{{ item.name }}.100do.se
export NOMAD_ADDR=https://nomad-{{ item.name }}.100do.se
consul members
nomad server members
```
