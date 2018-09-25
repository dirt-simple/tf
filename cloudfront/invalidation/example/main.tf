terraform {
  backend "s3" {
    # replace with your bucket/region/key
    bucket = "ops-config-mgmt"
    region = "us-east-1"
    key = "terraform-state/infrastructure/cloudfront-invalidation/terraform.tfstate"
  }
}

module "cloudfront_invalidation" {
    # local testing source
    source = "../"
  
    # actual source
    # source = "github.com/dirt-simple/tf/cloudfront/invalidation"

    # optional args
    # name = "<better_name>"
    # aws_region = "<region>"
    # lambda_concurrent_executions = <int>
    # invalidation_retries = <int>

}