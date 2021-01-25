data "aws_availability_zones" "azs" {
  state = "available"
}
data "aws_subnet" "custom" {
  for_each = toset(var.custom_subnet_ids)
  id       = each.value
}
#data "aws_subnet" "selected" {
#  count = var.create_networking ? 0 : 1
#  filter {
#    name   = "tag:Name"
#    values = [var.custom_subnet_ids] # insert values here
#  }
#
#locals {
#  az_names = data.aws_availability_zones.azs.names
#}
#locals {
#  "controller-ami-20.1.2" = {
#    us-west-2 = ""
#    us-west-1 = ""
#
#  }
#}
