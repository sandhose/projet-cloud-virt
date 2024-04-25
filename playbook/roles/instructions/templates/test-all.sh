#!/bin/sh

for i in {{ instances | join(" ") }}; do
  printf "=== %s\thttps://%s.consul.100do.se\thttps://%s.nomad.100do.se ===\n" "$i" "$i" "$i"
  CONSUL_HTTP_ADDR=https://$i.consul.100do.se consul members
  NOMAD_ADDR=https://$i.nomad.100do.se nomad server members
  echo
done
