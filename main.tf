module "directories" {
  source = "./0-directories"

  providers = {
    btp = btp
  }
}