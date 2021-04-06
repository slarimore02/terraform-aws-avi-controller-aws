locals {
  # AKO Settings
  cloud_settings = {
    se_mgmt_subnets     = var.create_networking ? local.mgmt_subnets : local.custom_mgmt_subnets
    vpc_id              = var.create_networking ? aws_vpc.avi[0].id : var.custom_vpc_id
    aws_region          = var.region
    controller_version  = var.controller_version,
    se_name_prefix      = var.name_prefix
    mgmt_security_group = aws_security_group.avi_se_mgmt_sg.id
    data_security_group = aws_security_group.avi_data_sg.id
    controller_ha       = var.controller_ha
    controller_name_1   = var.controller_ha ? aws_instance.avi_controller[0].tags["Name"] : null
    controller_ip_1     = var.controller_ha ? aws_instance.avi_controller[0].private_ip : null
    controller_name_2   = var.controller_ha ? aws_instance.avi_controller[1].tags["Name"] : null
    controller_ip_2     = var.controller_ha ? aws_instance.avi_controller[1].private_ip : null
    controller_name_3   = var.controller_ha ? aws_instance.avi_controller[2].tags["Name"] : null
    controller_ip_3     = var.controller_ha ? aws_instance.avi_controller[2].private_ip : null
  }
  mgmt_subnets = { for subnet in aws_subnet.avi : subnet.availability_zone =>
    {
      "mgmt_network_uuid" = subnet.id
      "mgmt_network_name" = subnet.tags["Name"]
    }
  }
  custom_mgmt_subnets = { for subnet in data.aws_subnet.custom : subnet.availability_zone =>
    {
      "mgmt_network_uuid" = subnet.id
      "mgmt_network_name" = subnet.tags["Name"]
    }
  }
  az_names = data.aws_availability_zones.azs.names
  avi_ami = {
    "20.1.4" = {
      "us-east-1" = "ami-0822ac66b62a893cc"
      "us-east-2" = "ami-08cf08a0ba5dcff76"
      "us-west-1" = "ami-0fa6c926c2fb340d3"
      "us-west-2" = "ami-08ecc90c68f430fc2"
    }
    "20.1.3" = {
      "us-east-1" = "ami-0ca5d1b0c6e2ef1f8"
      "us-east-2" = "ami-0786e4ed20b179355"
      "us-west-1" = "ami-064facee296f10111"
      "us-west-2" = "ami-0f1ba8c00dfd6c04c"
    }
    "20.1.2" = {
      "us-east-1" = "ami-090699c2c811f2960"
      "us-east-2" = "ami-0a2adfbfbd4c6da8e"
      "us-west-1" = "ami-0d440bb0a05717a19"
      "us-west-2" = "ami-08a85624884915308"
    }
    "18.2.11" = {
      "us-east-1" = "ami-071db10cf4818c77a"
      "us-east-2" = "ami-0858e11a36f912dcd"
      "us-west-1" = "ami-071db10cf4818c77a"
      "us-west-2" = "ami-07963584f136c2e33"
    }
  }
}
resource "aws_instance" "avi_controller" {
  count = var.controller_ha ? 3 : 1
  ami   = local.avi_ami[var.controller_version][var.region]
  root_block_device {
    volume_size           = var.root_disk_size
    delete_on_termination = true
  }
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  #availability_zone = var.create_networking ? aws_subnet.avi[count.index].availability_zone : 
  subnet_id              = var.create_networking ? aws_subnet.avi[count.index].id : var.custom_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.avi_controller_sg.id]
  iam_instance_profile   = var.create_iam ? aws_iam_instance_profile.avi[0].id : null
  tags = {
    Name = "${var.name_prefix}-avi-controller-${count.index + 1}"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}
resource "aws_ec2_tag" "custom_controller_1" {
  for_each    = var.custom_tags
  resource_id = aws_instance.avi_controller[0].id
  key         = each.key
  value       = each.value
}
resource "aws_ec2_tag" "custom_controller_2" {
  for_each    = var.controller_ha ? var.custom_tags : {}
  resource_id = aws_instance.avi_controller[1].id
  key         = each.key
  value       = each.value
}
resource "aws_ec2_tag" "custom_controller_3" {
  for_each    = var.controller_ha ? var.custom_tags : {}
  resource_id = aws_instance.avi_controller[2].id
  key         = each.key
  value       = each.value
}
resource "null_resource" "ansible_provisioner" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    controller_instance_ids = join(",", aws_instance.avi_controller.*.id)
  }

  connection {
    type        = "ssh"
    host        = aws_instance.avi_controller[0].public_ip
    user        = "admin"
    timeout     = "600s"
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    content = templatefile("${path.module}/files/avi-controller-aws-all-in-one-play.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/avi-controller-aws-all-in-one-play.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 180",
      "sudo /opt/avi/scripts/initialize_admin_user.py --password ${var.controller_password}",
      "ansible-playbook avi-controller-aws-all-in-one-play.yml -e password=${var.controller_password} -e aws_access_key_id=${var.aws_access_key} -e aws_secret_access_key=${var.aws_secret_key} > ansible-playbook.log 2> ansible-error.log",
      "echo Controller Configuration Completed"
    ]
  }
}
