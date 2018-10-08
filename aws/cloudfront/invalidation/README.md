# CloudFront Invalidator

The CloudFront Invalidator provides a retry mechanism for invalidations. 

CloudFront has invalidation request limits. If you exceed these limits, CloudFront will throw a `TooManyInvalidationsInProgress` error. Unless you handle this error yourself your invalidation will fail.

Caveats:

* Triggered by SNS.
* Processes one invalidation path at a time.
* Invalid requests are logged and ignored.
* There is no DLQ.

## Usage
Write to SNS to schedule an invalidation. The SNS Message must be JSON and contain the path and distribution_id keys.

Example:

```
# Message JSON
# {
# 	"path": "/some/path/*", 
# 	"distribution_id": "E2BI2JKRCBVC99"
# }

{
    "TopicArn": "arn:aws:sns:us-east-1:9999999999:cloudfront-invalidation",
    "Message": "{\"path\": \"/some/path/*\", \"distribution_id\": \"E2BI2JKRCBVC99\"}",
    "Subject": "my-app-name"
}

```

## CloudFront Limits
_CloudFront enforces concurrent invalidation request limits._

> If you're invalidating files individually, you can have invalidation requests for up to 3,000 files per distribution in progress at one time. This can be one invalidation request for up to 3,000 files, up to 3,000 requests for one file each, or any other combination that doesn't exceed 3,000 files. For example, you can submit 30 invalidation requests that invalidate 100 files each. As long as all 30 invalidation requests are still in progress, you can't submit any more invalidation requests. If you exceed the limit, CloudFront returns an error message.
>
>If you're using the * wildcard, you can have requests for up to 15 invalidation paths in progress at one time. You can also have invalidation requests for up to 3,000 individual files per distribution in progress at the same time; the limit on wildcard invalidation requests is independent of the limit on invalidating files individually.

## Diagram
![diagram](diagram.png)