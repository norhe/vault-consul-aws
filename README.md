# Vault POV Kit

This installs Vault and Consul on the same set of machines in a new VPC.  Recent versions of Ubuntu and RHEL/Centos are supported

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
