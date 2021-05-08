# AVI Controller Deployment on AWS Terraform module
This Terraform module creates and configures an AVI (NSX Advanced Load-Balancer) Controller on AWS

## Module Functions
The module is meant to be modular and can create all or none of the prerequiste resources needed for the AVI AWS Deployment including:
* VPC and Subnets for the Controller and SEs (optional with create_networking variable)
* IAM Roles, Policy, and Instance Profile (optional with create_iam variable)
* Security Groups for AVI Controller and SE communication
* AWS EC2 Instance using an official AVI AMI
* High Availability AVI Controller Deployment (optional with controller_ha variable)

During the creation of the Controller instance the following initialization steps are performed:
* Copy Ansible playbook to controller using the assigned public IP
* Run Ansible playbook to configure initial settings and AWS Full Access Cloud 


## Usage
This is an example of a controller deployment that leverages an existing VPC (with a cidr_block of 10.154.0.0/16) and 3 subnets. The public key is already created in EC2 and the private key found in the "/home/<user>/.ssh/id_rsa" will be used to copy and run the Ansible playbook to configure the Controller.
```hcl
terraform {
  backend "local" {
  }
}
module "avi-controller-aws" {
  source  = "slarimore02/avi-controller-aws/aws"
  version = "1.0.x"

  region = "us-west-1"
  aws_access_key = "<access-key>"
  aws_secret_key = "<secret-key>"
  create_networking = "false"
  create_iam = "false"
  controller_version = "20.1.3"
  custom_vpc_id = "vpc-<id>"
  custom_subnet_ids = ["subnet-<id>","subnet-<id>","subnet-<id>"]
  avi_cidr_block = "10.154.0.0/16"
  controller_password = "<newpassword>"
  key_pair_name = "<key>"
  private_key_path = "/home/<user>/.ssh/id_rsa"
  name_prefix = "<name>"
  custom_tags = { "Role" : "Avi-Controller", "Owner" : "admin", "Department" : "IT", "shutdown_policy" : "noshut" }
}
output "controller_ip" { 
  value = module.avi_controller_aws.public_address
}
output "ansible_variables" {
  value = module.avi_controller_aws.ansible_variables
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.6 |
| aws | ~> 3.25.0 |
| null | 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.25.0 |
| null | 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_gslb\_sites | The Names and IP addresses of the GSLB Sites that will be configured. | `list(object({ name = string, ip_address = string, dns_vs_name = string }))` | <pre>[<br>  {<br>    "dns_vs_name": "",<br>    "ip_address": "",<br>    "name": ""<br>  }<br>]</pre> | no |
| avi\_cidr\_block | The CIDR that will be used for creating a subnet in the AVI VPC - a /16 should be provided | `string` | `"10.255.0.0/16"` | no |
| avi\_version | The AVI Controller version that will be deployed | `string` | n/a | yes |
| aws\_access\_key | The Access Key that will be used to deploy AWS resources | `string` | n/a | yes |
| aws\_secret\_key | The Secret Key that will be used to deploy AWS resources | `string` | n/a | yes |
| boot\_disk\_size | The boot disk size for the Avi controller | `number` | `128` | no |
| configure\_dns\_profile | Configure Avi DNS Profile for DNS Record Creation for Virtual Services. If set to true the dns\_service\_domain variable must also be set | `bool` | `"false"` | no |
| configure\_dns\_route\_53 | Configures Avi Cloud with Route53 DNS Provider. The following variables must be set to false if enabled: configure\_dns\_profile, configure\_dns\_vs, configure\_gslb | `bool` | `"false"` | no |
| configure\_dns\_vs | Create Avi DNS Virtual Service. The configure\_dns\_profile variable must also be set to true | `bool` | `"false"` | no |
| configure\_gslb | Configure GSLB. The gslb\_site\_name, gslb\_domains, and configure\_dns\_vs variables must also be set. Optionally the additional\_gslb\_sites variable can be used to add active GSLB sites | `bool` | `"false"` | no |
| configure\_gslb\_additional\_sites | Configure Additional GSLB Sites. The additional\_gslb\_sites, gslb\_site\_name, gslb\_domains, and configure\_dns\_vs variables must also be set. Optionally the additional\_gslb\_sites variable can be used to add active GSLB sites | `bool` | `"false"` | no |
| controller\_ha | If true a HA controller cluster is deployed and configured | `bool` | `"false"` | no |
| controller\_password | The password that will be used authenticating with the AVI Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters | `string` | n/a | yes |
| create\_iam | Create IAM Service Account, Roles, and Role Bindings for Avi GCP Full Access Cloud | `bool` | `"false"` | no |
| create\_networking | This variable controls the VPC and subnet creation for the AVI Controller. When set to false the custom-vpc-name and custom-subnetwork-name must be set. | `bool` | `"true"` | no |
| custom\_subnet\_ids | This field can be used to specify a list of existing VPC Subnets for the controller and SEs. The create-networking variable must also be set to false for this network to be used. | `list(string)` | `null` | no |
| custom\_tags | Custom tags added to AWS Resources created by the module | `map(string)` | `{}` | no |
| custom\_vpc\_id | This field can be used to specify an existing VPC for the controller and SEs. The create-networking variable must also be set to false for this network to be used. | `string` | `null` | no |
| dns\_search\_domain | The optional DNS search domain that will be used by the controller | `string` | `null` | no |
| dns\_servers | The optional DNS servers that will be used for local DNS resolution by the controller. Example ["8.8.4.4", "8.8.8.8"] | `list(string)` | `null` | no |
| dns\_service\_domain | The DNS Domain that will be available for Virtual Services. Avi will be the Authorative Nameserver for this domain and NS records may need to be created pointing to the Avi Service Engine addresses. An example is demo.Avi.com | `string` | `""` | no |
| dns\_vs\_settings | Settings for the DNS Virtual Service. The subnet\_name must be an existing AWS Subnet. If the allocate\_public\_ip option is set to true a EIP will be allocated for the VS. The VS IP address will automatically be allocated via the AWS IPAM. Example:{ subnet\_name = "subnet-dns", allocate\_public\_ip = "true" } | `object({ subnet_name = string, allocate_public_ip = bool })` | `null` | no |
| email\_config | The Email settings that will be used for sending password reset information or for trigged alerts. The default setting will send emails directly from the Avi Controller | `object({ smtp_type = string, from_email = string, mail_server_name = string, mail_server_port = string, auth_username = string, auth_password = string })` | <pre>{<br>  "auth_password": "",<br>  "auth_username": "",<br>  "from_email": "admin@avicontroller.net",<br>  "mail_server_name": "localhost",<br>  "mail_server_port": "25",<br>  "smtp_type": "SMTP_LOCAL_HOST"<br>}</pre> | no |
| gslb\_domains | A list of GSLB domains that will be configured | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| gslb\_site\_name | The name of the GSLB site the deployed Controller(s) will be a member of. | `string` | `""` | no |
| instance\_type | The EC2 instance type for the Avi Controller | `string` | `"m5.2xlarge"` | no |
| key\_pair\_name | The name of the existing EC2 Key pair that will be used to authenticate to the Avi Controller | `string` | n/a | yes |
| name\_prefix | This prefix is appended to the names of the Controller and SEs | `string` | n/a | yes |
| ntp\_servers | The NTP Servers that the Avi Controllers will use. The server should be a valid IP address (v4 or v6) or a DNS name. Valid options for type are V4, DNS, or V6 | `list(object({ addr = string, type = string }))` | <pre>[<br>  {<br>    "addr": "0.us.pool.ntp.org",<br>    "type": "DNS"<br>  },<br>  {<br>    "addr": "1.us.pool.ntp.org",<br>    "type": "DNS"<br>  },<br>  {<br>    "addr": "2.us.pool.ntp.org",<br>    "type": "DNS"<br>  },<br>  {<br>    "addr": "3.us.pool.ntp.org",<br>    "type": "DNS"<br>  }<br>]</pre> | no |
| private\_key\_path | The local private key path for the EC2 Key pair used for authenticating to the Avi Controller | `string` | n/a | yes |
| region | The Region that the AVI controller and SEs will be deployed to | `string` | n/a | yes |
| se\_ha\_mode | The HA mode of the Service Engine Group. Possible values active/active, n+m, or active/standby | `string` | `"active/active"` | no |

## Outputs

| Name | Description |
|------|-------------|
| public\_address | Public IP Addresses for the AVI Controller(s) |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
