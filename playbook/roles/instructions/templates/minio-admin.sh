#!/bin/sh

{% for instance in instances %}
mc admin user add cloudvirt {{ instance }} {{ lookup("file", "./instructions/per-group/" + instance + "/minio") }}
mc admin policy set cloudvirt rwownbucket user={{ instance }}
{% endfor %}
