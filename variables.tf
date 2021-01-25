variable "region" {
  description = "The Region that the AVI controller and SEs will be deployed to"
  type        = string
}
variable "aws_access_key" {
  description = "The Access Key that will be used to deploy AWS resources"
  type        = string
  sensitive   = true
}
variable "aws_secret_key" {
  description = "The Secret Key that will be used to deploy AWS resources"
  type        = string
  sensitive   = true
}
variable "key_pair_name" {
  description = "The name of the existing EC2 Key pair that will be used to authenticate to the Avi Controller"
  type        = string
}
variable "private_key_path" {
  description = "The local private key path for the EC2 Key pair used for authenticating to the Avi Controller"
  type        = string
  sensitive   = true
}
variable "controller_version" {
  description = "The AVI Controller version that will be deployed"
  type        = string
}
variable "name_prefix" {
  description = "This prefix is appended to the names of the Controller and SEs"
  type        = string
}
variable "controller_ha" {
  description = "If true a HA controller cluster is deployed and configured"
  type        = bool
  default     = "false"
}
variable "create_networking" {
  description = "This variable controls the VPC and subnet creation for the AVI Controller. When set to false the custom-vpc-name and custom-subnetwork-name must be set."
  type        = bool
  default     = "true"
}
variable "avi_cidr_block" {
  description = "The CIDR that will be used for creating a subnet in the AVI VPC - a /16 should be provided "
  type        = string
  default     = "10.255.0.0/16"
}
variable "custom_vpc_id" {
  description = "This field can be used to specify an existing VPC for the controller and SEs. The create-networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}
variable "custom_subnet_ids" {
  description = "This field can be used to specify a list of existing VPC Subnets for the controller and SEs. The create-networking variable must also be set to false for this network to be used."
  type        = list(string)
  default     = null
}
variable "create_iam" {
  description = "Create IAM Service Account, Roles, and Role Bindings for Avi GCP Full Access Cloud"
  type        = bool
  default     = "false"
}
variable "controller_password" {
  description = "The password that will be used authenticating with the AVI Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.controller_password) > 7
    error_message = "The controller_password value must be more than 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters."
  }
}
variable "instance_type" {
  description = "The EC2 instance type for the AVI Controller"
  type        = string
  default     = "m5.2xlarge"
}
variable "root_disk_size" {
  description = "The root disk size for the AVI controller"
  type        = number
  default     = 128
  validation {
    condition     = var.root_disk_size >= 128
    error_message = "The Controller root disk size should be greater than or equal to 128 GB."
  }
}
variable "custom_tags" {
  description = "Custom tags added to AWS Resources created by the module"
  type        = map(string)
  default     = {}
}