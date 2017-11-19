#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Installing Vault...\nChecking for existing file"

if ls /tmp/vault*zip 1> /dev/null 2>&1;
then
  VAULT_ZIP=$(find /tmp/ -name vault* -printf "%f")
  echo "Found local file: $VAULT_ZIP"
else
  VAULT_VERSION="$(curl -s https://releases.hashicorp.com/vault/index.json | jq -r '.versions[].version' | grep -v 'beta\|rc' | tail -n 1)"
  VAULT_ZIP="vault_${VAULT_VERSION}_linux_amd64.zip"
  VAULT_URL=${URL:-"https://releases.hashicorp.com/vault/${VAULT_VERSION}/${VAULT_ZIP}"}

  logger "Downloading vault ${VAULT_VERSION}"
  curl --silent --output /tmp/${VAULT_ZIP} ${VAULT_URL}
fi

logger "Installing vault"
sudo unzip -o /tmp/${VAULT_ZIP} -d /usr/local/bin/
sudo chmod 0755 /usr/local/bin/vault
sudo chown vault:vault /usr/local/bin/vault
sudo mkdir -pm 0755 /etc/vault.d
sudo mkdir -pm 0755 /etc/ssl/vault

logger "/usr/local/bin/vault --version: $(/usr/local/bin/vault --version)"

logger "Configuring vault"
sudo chown -R vault:vault /etc/vault.d /etc/ssl/vault
sudo chmod -R 0644 /etc/vault.d/*
echo "export VAULT_ADDR=http://127.0.0.1:8200" | sudo tee /etc/profile.d/vault.sh

logger "Complete"
