# Lambda@Edge Single Page App Lambda

The Single Page App Lambda... 


## Module Usage
```
module "edge_spa" {
  source = "github.com/dirt-simple/tf/aws/cloudfront/lambda-edge/single-page-app"
}
```

## Argument Reference
The following arguments are supported:

* `name` - (Optional) All resources created will use this name. The default for this attribute is cloudformation-invalidation.

* `aws_region` - (Optional) The AWS region that all resources will be created in. The default for this attribute is us-east-1.

## Attributes Reference
In addition to all arguments above, the following attributes are exported:

* `lambda-arn` - The ARN for the created Lambda.

* `lambda-version` - The version of the Lambda.
