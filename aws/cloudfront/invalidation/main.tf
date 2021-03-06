variable "aws_region" {
  description = "The AWS region"
  default     = "us-east-1"
}

variable "name" {
  description = "This will be the name/prefix of all resources created"
  default     = "cloudfront-invalidation"
}

variable "lambda_concurrent_executions" {
  description = "Max concurrent invalidation lambdas."
  default     = 1
}

variable "invalidation_max_retries" {
  description = "How may times to try to invalidate a path."
  default     = 20
}

variable "invalidation_retry_timeout" {
  description = "How long to wait between retries. Max is 900"
  default     = 300
}

variable "sqs_message_retention_seconds" {
  default = "86400"
}

variable "sqs_receive_wait_time_seconds" {
  default = "10"
}

variable "sqs_batch_size" {
  description = "10 is the max for SQS"
  default = 10
}

provider "aws" {
  region = "${var.aws_region}"
}

# Reusable policy document
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "archive_file" "sqs_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "sqs_lambda" {
  filename                       = "${path.module}/lambda_function.zip"
  function_name                  = "${var.name}"
  role                           = "${aws_iam_role.sqs_lambda.arn}"
  handler                        = "index.handler"
  source_code_hash               = "${data.archive_file.sqs_lambda.output_base64sha256}"
  runtime                        = "nodejs6.10"
  reserved_concurrent_executions = "${var.lambda_concurrent_executions}"
  environment {
    variables = {
      INVALIDATION_MAX_RETRIES = "${var.invalidation_max_retries}"
      INVALIDATION_RETRY_TIMOUT = "${var.invalidation_retry_timeout}"
    }
  }
}

resource "aws_iam_role" "sqs_lambda" {
  name               = "${var.name}"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role.json}"
}

data "aws_iam_policy_document" "sqs_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]

    resources = ["${aws_sqs_queue.sqs_queue.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:ListQueues"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sqs_lambda" {
  name   = "generated-policy"
  role   = "${aws_iam_role.sqs_lambda.name}"
  policy = "${data.aws_iam_policy_document.sqs_lambda.json}"
}

resource "aws_sns_topic" "sns_topic" {
  name = "${var.name}"
}

resource "aws_sqs_queue" "sqs_queue" {
  name                      = "${var.name}"
  message_retention_seconds = "${var.sqs_message_retention_seconds}"
  receive_wait_time_seconds = "${var.sqs_receive_wait_time_seconds}"
}

resource "aws_sns_topic_subscription" "sqs_subscribe" {
  topic_arn = "${aws_sns_topic.sns_topic.arn}"
  endpoint  = "${aws_sqs_queue.sqs_queue.arn}"
  protocol  = "sqs"
}

resource "aws_lambda_event_source_mapping" "sqs_worker" {
  enabled          = true
  batch_size       = "${var.sqs_batch_size}"
  event_source_arn = "${aws_sqs_queue.sqs_queue.arn}"
  function_name    = "${aws_lambda_function.sqs_lambda.arn}"
}

resource "aws_sqs_queue_policy" "sqs_queue" {
  queue_url = "${aws_sqs_queue.sqs_queue.id}"
  policy    = "${data.aws_iam_policy_document.sqs_queue.json}"
}

data "aws_iam_policy_document" "sqs_queue" {
  policy_id = "generated-policy"

  statement {
    actions = [
      "sqs:SendMessage",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        "${aws_sns_topic.sns_topic.arn}",
        "${aws_lambda_function.sqs_lambda.arn}",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_sqs_queue.sqs_queue.arn}",
    ]
  }
}

output "sns-topic-arn" {
  value = "${aws_sns_topic.sns_topic.arn}"
}

output "sns-topic-id" {
  value = "${aws_sns_topic.sns_topic.id}"
}
