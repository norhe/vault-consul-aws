#!/usr/bin/env bash
set -x

CONSUL_SERVER_COUNT="${1}"

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running"

# ui=true is only valid for Enterprise version, remove if using Vault open source
sudo bash -c "cat >/etc/vault.d/vault.hcl" << 'EOF'
backend "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
ui=true
EOF

if [ "$CONSUL_SERVER_COUNT" == "1" ]; then
# single host example - comment out this section if using multiple consul servers
sudo bash -c "cat >/etc/consul.d/consul.json" << EOF
{
  "server": true,
  "bootstrap_expect": 1,
  "advertise_addr": "$(/usr/sbin/ifconfig enp0s8 | grep 'inet ' | awk '{print $2}')",
  "leave_on_terminate": true,
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true
}
EOF

elif [ "$CONSUL_SERVER_COUNT" != "1" ]; then
# multi server example - edit IP addresses, datacenter name, and comment out single server example
sudo bash -c "cat >/etc/consul.d/consul.json" << EOF
{
  "server": true,
  "bootstrap_expect": $CONSUL_SERVER_COUNT,
  "datacenter": "datacenter-name",
  "retry_join": ["provider=aws tag_key=consul_server tag_value=true"],
  "advertise_addr": "$(/usr/sbin/ifconfig enp0s8 | grep 'inet ' | awk '{print $2}')",
  "leave_on_terminate": true,
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true
}
EOF
else
logger "Invalid server count selected, exiting.."
exit 1
fi

sudo chown -R consul:consul /etc/consul.d /opt/consul
sudo chmod -R 0644 /etc/consul.d/*
sudo chown -R vault:vault /etc/vault.d /etc/ssl/vault
sudo chmod -R 0644 /etc/vault.d/*
