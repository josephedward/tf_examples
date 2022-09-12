# ECS role for container instances

resource "aws_iam_instance_profile" "ecs-instance" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs-instance.name
}

resource "aws_iam_role" "ecs-instance" {
  name = "ecs-instance"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs-instance-runtime" {
  name = "ecs-instance-runtime"
  role = aws_iam_role.ecs-instance.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecs:StartTask",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action":[
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# ECS execution role for the router

resource "aws_iam_role" "router-execution" {
  name = "platform-router-execution"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "router-execution-ecr" {
  name = "platform-router-execution-ecr"
  role = aws_iam_role.router-execution.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "router-cloudwatch-logs" {
  name = "platform-router-cloudwatch-logs"
  role = aws_iam_role.router-execution.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "${aws_cloudwatch_log_group.router.arn}:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "platform-cloudwatch-logs" {
  name = "platform-cloudwatch-logs"
  role = aws_iam_role.router-execution.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "${aws_cloudwatch_log_group.platform.arn}:*"
    }
  ]
}
EOF
}

# ECS task role for the router

resource "aws_iam_role" "router-task" {
  name = "platform-router-task"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#TODO: User variable for cognito pool id
resource "aws_iam_role_policy" "router-task-cognito" {
  name = "platform-router-task-cognito"
  role = aws_iam_role.router-task.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cognito-idp:ListUsers"
      ],
      "Resource": [
        "arn:aws:cognito-idp:us-east-1:${var.public.account_id}:userpool/us-east-1_SlBDp9xy2"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "router-task-ecs" {
  name = "platform-router-task-ecs"
  role = aws_iam_role.router-task.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "ecs:DescribeContainerInstances",
                "ecs:DescribeTasks",
                "ecs:RunTask",
                "ecs:StopTask"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# TODO: replace resource with below
#resource "aws_iam_role_policy" "router-task-passrole" {
#  name = "platform-router-task-passrole"
#  role = aws_iam_role.router-task.id
#
#  policy = <<EOF
#{
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Action": [
#                "iam:GetRole",
#                "iam:PassRole"
#            ],
#            "Resource": [
#              "${data.terraform_remote_state.content.outputs.content-execution-role-arn}"
#            ]
#        }
#    ]
#}
#EOF
#}

# ECS task role for api-alarm

resource "aws_iam_role" "api-alarm-task" {
  name = "platform-api-alarm-task"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "api-directory-task" {
  name = "platform-api-directory-task"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "api-directory-task-ses" {
  name = "platform-api-directory-task-ses"
  role = aws_iam_role.api-directory-task.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendTemplatedEmail"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "api-directory-task-lambda" {
  name = "platform-api-directory-task-lambda"
  role = aws_iam_role.api-directory-task.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": "arn:aws:lambda:*"
        }
    ]
}
EOF
}

# TODO: s3 bucket name should be variable
resource "aws_iam_role_policy" "api-directory-task-s3" {
  name = "platform-api-directory-task-s3"
  role = aws_iam_role.api-directory-task.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::dev-hackedu-content/courses/manifest.json"
        }
    ]
}
EOF
}


resource "aws_iam_role" "firehose-to-s3-role" {
  name = "firehose-to-s3-hose"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": { "Service": "firehose.amazonaws.com" },
    "Action": "sts:AssumeRole",
    "Condition": { "StringEquals": { "sts:ExternalId":"${var.public.account_id}" } }
  }
}
EOF
}

resource "aws_iam_role_policy" "firehose-to-s3-role-policy" {
  name = "firehose-to-s3-role-policy"
  role = aws_iam_role.firehose-to-s3-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject" ],
      "Resource": [
          "arn:aws:s3:::${var.public.s3.hackedu_logs_dev_bucket}",
          "arn:aws:s3:::${var.public.s3.hackedu_logs_dev_bucket}/*" ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "cloud-watch-to-kinesis-firehose" {
  name = "cloud-watch-to-kinesis-firehose"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": { "Service": "logs.us-east-1.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy" "cloud-watch-to-kinesis-firehose-policy" {
  name = "cloud-watch-to-kinesis-firehose-policy"
  role = aws_iam_role.cloud-watch-to-kinesis-firehose.id

  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement":[
      {
        "Effect":"Allow",
        "Action":["firehose:*"],
        "Resource":["arn:aws:firehose:us-east-1:${var.public.account_id}:*"]
      }
    ]
}
EOF
}

# TODO: Cognito pool should be variable
resource "aws_iam_role_policy" "api-hacker-task-cognito" {
  name = "platform-api-hacker-task-cognito"
  role = aws_iam_role.api-hacker-task.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
        "Effect": "Allow",
        "Action": [
            "cognito-idp:AdminUpdateUserAttributes"
        ],
        "Resource": "arn:aws:cognito-idp:us-east-1:${var.public.account_id}:userpool/us-east-1_SlBDp9xy2"
    }
  ]
}
EOF
}
