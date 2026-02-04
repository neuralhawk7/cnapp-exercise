terraform {
  backend "remote" {
    organization = "neuralhawk7-org"

    workspaces {
      name = "cnapp-exercise"
    }
  }
}
