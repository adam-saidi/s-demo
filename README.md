# Sky Demo - SRE Practical Exercise

Launch and manage resources within GCP using Terraform - code contains: GKE cluster, Postgre SQL, Big Query Dataset

## How It All Works

All the resources are stored within Virtual Private Cloud with firewall rules only allowing SSH connections into proxy where the SSH public key is recognised. Within GKE instance, 
CloudSQL instance holds a private IP address that can only be accessed from within the VPC.

Client Public key (id_rsa.pub) will need to be added into GCP OS-Login to allow SSH connection to work

Example command on Linux Command Line: gcloud compute os-login ssh-keys add  --key-file=<directory>.ssh/<public-facing-ssh-key>.pub

## 

## Launch Terraform Commands To Deploy GCP Resources

```
$ terraform init
$ terraform plan
$ terraform apply
```


## Questions?

Contact adamsaidi96@gmail.com

Thank you,

Adam
