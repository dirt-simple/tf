terraform {
  backend "s3" {
    # replace with your bucket/region/key
    bucket = "ops-config-mgmt"
    region = "us-east-1"
    key    = "tfstate/infrastructure/cloudflare_single_worker_example/terraform.tfstate"
  }
}

module "single_worker" {
  source                  = "../"
  enabled_route_patterns  = ["blog.beeceej.com/*"]
  disabled_route_patterns = ["blog.beeceej.com/"]
  account_zone            = "beeceej.com"
  script_path             = "worker/index.js"
}
