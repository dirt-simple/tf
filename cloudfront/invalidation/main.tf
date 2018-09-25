variable "aws_region" {
    description = "The AWS region"
    default = "us-east-1"
}

variable "name" {
    description = "This will be the name/prefix of all resources created"
    default = "cloudfront-invalidation"
}

variable "lambda_concurrent_executions" {
    description = "Max concurrent invalidation lambdas."
    default = 10
}

variable "invalidation_retries" {
    description = "How may times to try to invalidate a path."
    default = 10
}

provider "aws" {
    region = "${var.aws_region}"
}


# Reusable policy document
data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
        type = "Service"
        identifiers = ["lambda.amazonaws.com"]
        }
    }
}

# SQS Lambda
data "archive_file" "sqs_lambda" {
    type = "zip"
    source_file = "${path.module}/lambda/index.js"
    output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "sqs_lambda" {
    filename = "${path.module}/lambda_function.zip"
    function_name = "${var.name}"
    role = "${aws_iam_role.sqs_lambda.arn}"
    handler = "index.handler"
    source_code_hash = "${data.archive_file.sqs_lambda.output_base64sha256}"
    runtime = "nodejs6.10"
    reserved_concurrent_executions = "${var.lambda_concurrent_executions}"
}


resource "aws_iam_role" "sqs_lambda" {
    name = "${var.name}"
    assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role.json}"
}

data "aws_iam_policy_document" "sqs_lambda" {
    statement {
    effect = "Allow"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
    }
    statement {
    effect = "Allow"
    actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility"
    ]
    resources = ["${aws_sqs_queue.sqs_queue.arn}"]
    }
}

resource "aws_iam_role_policy" "sqs_lambda" {
    name = "generated-policy"
    role = "${aws_iam_role.sqs_lambda.name}"
    policy = "${data.aws_iam_policy_document.sqs_lambda.json}"
}
# End SQS Lambda


# Start SNS
resource "aws_sns_topic" "sns_topic" {
    name = "${var.name}"
}
# End SNS

# Start DLQ
resource "aws_sqs_queue" "sqs_dead_queue" {
    name = "${var.name}-dlq"
}
# End DLQ

# Start SQS
resource "aws_sqs_queue" "sqs_queue" {
    name = "${var.name}"
    message_retention_seconds = 86400
    receive_wait_time_seconds = 10
    redrive_policy = <<-JSON
    {
        "deadLetterTargetArn": "${aws_sqs_queue.sqs_dead_queue.arn}",
        "maxReceiveCount": ${var.invalidation_retries}
    }
    JSON
}

resource "aws_sns_topic_subscription" "sqs" {
    topic_arn = "${aws_sns_topic.sns_topic.arn}"
    endpoint  = "${aws_sqs_queue.sqs_queue.arn}"
    protocol  = "sqs"
}

resource "aws_lambda_event_source_mapping" "worker" {
    enabled = true
    batch_size = 10
    event_source_arn = "${aws_sqs_queue.sqs_queue.arn}"
    function_name    = "${aws_lambda_function.sqs_lambda.arn}"
}


resource "aws_sqs_queue_policy" "sqs_queue" {
    queue_url = "${aws_sqs_queue.sqs_queue.id}"
    policy = "${data.aws_iam_policy_document.sqs_queue.json}"
}

data "aws_iam_policy_document" "sqs_queue" {
    policy_id = "generated-policy"
    statement {
    actions = [
        "sqs:SendMessage",
    ]
    condition {
        test = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
            "${aws_sns_topic.sns_topic.arn}",
        ]
    }
    effect = "Allow"
    principals {
        type = "AWS"
        identifiers = ["*"]
    }
    resources = [
            "${aws_sqs_queue.sqs_queue.arn}",
        ]
    }
}
# End SQS

output "sns-topic-arn" {
    value = "${aws_sns_topic.sns_topic.arn}"
}

output "sns-topic-id" {
    value = "${aws_sns_topic.sns_topic.id}"
}
