
output "ssh_command" {
  value = "ssh -i ${var.path_ssh_key} root@${ibm_is_floating_ip.fip.address}"
}
