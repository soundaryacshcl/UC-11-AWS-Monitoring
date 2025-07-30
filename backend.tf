terraform {
  backend "s3" {
    bucket       = "terraform-stateuc-bucketttt"
    key          = "usecase11/statefile.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = false
  }
}