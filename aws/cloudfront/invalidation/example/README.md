# Cloudfront Invalidator


```
module "cloudfront_invalidation" {
  source = "github.com/dirt-simple/tf/aws/cloudfront/invalidation"
}
```

## Argument Reference
The following arguments are supported:

* `name` - (Optional) All resources created will use this name. The default for this attribute is cloudformation-invalidation.

* `aws_region` - (Optional) The AWS region that all resources will be created in. The default for this attribute is us-east-1.

* `lambda_concurrent_executions` - (Optional) The number of concurrent Lambda executions. The default for this attribute is 1.

* `invalidation_max_retries` - (Optional) How many attempts to invalidate a path. The default for this attribute is 20.

* `invalidation_retry_timeout` - (Optional) How long to wait between invalidation attempts. An integer from 0 to 900 (15 minutes). The default for this attribute is 300 seconds (five minutes).

* `sqs_message_retention_seconds` - (Optional) The number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days). The default for this attribute is 86400 (1 day).

* `sqs_receive_wait_time_seconds` - (Optional) The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds). The default for this attribute is 10 seconds.

## Attributes Reference
In addition to all arguments above, the following attributes are exported:

* `sns-topic-arn` - The ARN for the created Amazon SNS topic.

* `sns-topic-id` - The ID for the created Amazon SNS topic.

## Resource Reference
* [Lambda](https://docs.aws.amazon.com/lambda/index.html)
* [SNS](https://docs.aws.amazon.com/sns/index.html)
* [SQS](https://docs.aws.amazon.com/sqs/index.html)
* [IAM](https://docs.aws.amazon.com/iam/index.html)