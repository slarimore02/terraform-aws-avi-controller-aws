output "controller_info" {
  description = "Avi Controller IP Address"
  value       = module.avi_controller_aws.controllers
}