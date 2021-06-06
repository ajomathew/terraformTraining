locals {
  location = {
    "aus" = "australiaeast",
    "us" = "useast"
  }
  required_software_for_docker = [
    "apt-transport-https","ca-certificates","curl","gnupg-agent","software-properties-common"
  ]
  docker_packages = [
    "docker-ce", "docker-ce-cli", "containerd.io"
  ]
}

output "output_as_list" {
     
    value = [for l in local.required_software_for_docker: l ]
}

output "output_to_map" {
     
    value = {for l in local.required_software_for_docker: l => upper(l)}
}

output "print_list" {
  value = (join(",",local.required_software_for_docker))
}