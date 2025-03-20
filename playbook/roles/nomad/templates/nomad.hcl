{{ ansible_managed | comment }}

# Group name
datacenter = "{{ main_instance_group.name }}"

# Node name
name = "{{ inventory_hostname }}"

# Save the persistent data to /opt/nomad
data_dir = "/opt/nomad"

# Allow clients to connect from any interface
bind_addr = "0.0.0.0"

advertise {
  # We explicitely advertise the IP on the vxlan interface
  http = "{{ main_instance_group.network | ansible.utils.ipaddr(host_index) | ansible.utils.ipaddr('address') }}"
  rpc = "{{ main_instance_group.network | ansible.utils.ipaddr(host_index) | ansible.utils.ipaddr('address') }}"
  serf = "{{ main_instance_group.network | ansible.utils.ipaddr(host_index) | ansible.utils.ipaddr('address') }}"
}

# This node is a server, and expects to be the only server in the cluster
server {
  enabled = true
  bootstrap_expect = 1
}

# This node is not running jobs
client {
  enabled = false
}

# Connect to the local Consul agent
consul {
  address = "127.0.0.1:8500"
}

# Show the UI and link to the Consul UI
ui {
  enabled = true

  consul {
    ui_url = "https://{{ main_instance_group.name }}.consul.100do.se/ui"
  }
}
