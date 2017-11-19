#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Installing Consul...\nChecking for existing file"

if ls /tmp/consul*zip 1> /dev/null 2>&1;
then
  CONSUL_ZIP=$(find /tmp/ -name consul* -printf "%f")
  echo "Found local file: $CONSUL_ZIP"
else
  CONSUL_VERSION="$(curl -s https://releases.hashicorp.com/consul/index.json | jq -r '.versions[].version' | grep -v 'beta\|rc' | tail -n 1)"
  CONSUL_ZIP="consul_${CONSUL_VERSION}_linux_amd64.zip"
  CONSUL_URL=${URL:-"https://releases.hashicorp.com/consul/${CONSUL_VERSION}/${CONSUL_ZIP}"}

  logger "Downloading consul ${CONSUL_VERSION}"
  curl --silent --output /tmp/${CONSUL_ZIP} ${CONSUL_URL}
fi

logger "Installing consul"
sudo unzip -o /tmp/${CONSUL_ZIP} -d /usr/local/bin/
sudo chmod 0755 /usr/local/bin/consul
sudo chown consul:consul /usr/local/bin/consul
sudo mkdir -pm 0755 /etc/consul.d
sudo mkdir -pm 0755 /opt/consul/data

logger "/usr/local/bin/consul --version: $(/usr/local/bin/consul --version)"

logger "Configuring consul"
sudo cp /tmp/consul/config/* /etc/consul.d/
sudo chown -R consul:consul /etc/consul.d /opt/consul
sudo chmod -R 0644 /etc/consul.d/*

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

if [[ ! -z ${YUM} ]]; then
  logger "Installing dnsmasq"
  sudo yum install -q -y dnsmasq
elif [[ ! -z ${APT_GET} ]]; then
  logger "Installing dnsmasq"
  sudo apt-get -qq -y update
  sudo apt-get install -qq -y dnsmasq-base dnsmasq
else
  logger "Dnsmasq not installed due to OS detection failure"
  exit 1;
fi

logger "Configuring dnsmasq to forward .consul requests to consul port 8600"
sudo sh -c 'echo "server=/consul/127.0.0.1#8600" >> /etc/dnsmasq.d/consul'
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

logger "Complete"
