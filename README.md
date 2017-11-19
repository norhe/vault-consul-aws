# Vault with Consul backend AWS

This installs Vault and Consul on the same set of machines in a new VPC.  Recent versions of Ubuntu and RHEL/Centos are supported.

## Installing Consul and Vault

If you have been provided with binaries then place the zip files in which they were delivered into the `binaries` directory.  If no binaries are present than the servers will download the latest open source versions.

## Instructions

Source your AWS creds.

```
git clone vault-pov && cd vault-pov
cp ~/Downloads/consul*.zip binaries/
cp ~/Downloads/vault*.zip binaries/
terraform plan
terraform apply
```

## Caveats

Use username ubuntu for Ubuntu, centos for Centos deploys.  Only tested on the latest version of both.

## Next steps

This deployment does not use TLS.  You should absolutely use TLS!  Set the appropriate hostnames, generate, and sign CSRs.  After you have the appropriate certificate and key file you can update your Vault config.

```
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/etc/certs/vault.crt"
  tls_key_file  = "/etc/certs/vault.key"
}
```
