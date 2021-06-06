resource "github_repository" "tf-training" {
  name        = "tf-training"
  description = "Terraform Training"

  visibility = "public"

  # template {
  #   owner      = "ajomathew"
  #   repository = "ajomathew.github.io"
  # }
}