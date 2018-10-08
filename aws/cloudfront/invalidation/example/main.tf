terraform {
  backend "s3" {
    # replace with your bucket/region/key
    bucket = "ops-config-mgmt"
    region = "us-east-1"
    key    = "terraform-state/infrastructure/cloudfront-invalidation/terraform.tfstate"
  }
}

module "cloudfront_invalidation" {
  # local testing source
  source = ".."
  lambda_concurrent_executions = "1"

  # actual source
  // source = "github.com/dirt-simple/tf/aws/cloudfront/invalidation"

  # optional args
  // name = "<better_name>"
  // aws_region = "<region>"
  // lambda_concurrent_executions = <int>
  // invalidation_max_retries = <int>
  // invalidation_retry_timeout = <int>
  // sqs_message_retention_seconds = <int>
  // sqs_receive_wait_time_seconds = <int>
}
