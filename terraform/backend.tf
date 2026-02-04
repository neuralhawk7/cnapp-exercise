terraform {
  backend "remote" {
    organization = "YOUR_ORG"

    workspaces {
      name = "cnapp-exercise"
    }
  }
}
