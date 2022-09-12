# Load balancer access logs
resource "aws_s3_bucket" "access-logs" {
  bucket        = var.public.s3.access_logs_bucket
  acl           = "private"

  tags = {
    Name = "hackedu-access-logs"
  }
}

# Load balancer access logs
resource "aws_s3_bucket" "hackedu-logs-dev" {
  bucket        = var.public.s3.hackedu_logs_dev_bucket
  acl           = "private"

  tags = {
    Name = "hackedu-logs-dev"
  }
}

resource "aws_s3_bucket_policy" "access-logs-production-alb" {
  bucket = aws_s3_bucket.access-logs.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "access-logs-alb",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.current.arn}"
      },
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.access-logs.arn}/production-router-alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        "${aws_s3_bucket.access-logs.arn}/platform/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      ]
    },
    {
      "Sid": "AWSLogDeliveryWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": [
        "${aws_s3_bucket.access-logs.arn}/production-router-alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        "${aws_s3_bucket.access-logs.arn}/platform/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      ],
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.access-logs.arn}"
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "root" {
  bucket = var.public.urls.root
  acl    = "public-read"
  policy = jsonencode(
    {
      "Id": "bucket_policy_site",
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "bucket_policy_site_main",
          "Action": [
            "s3:GetObject"
          ],
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${var.public.urls.root}/*",
          "Principal": "*"
        }
      ]
    }
  )

  website {
    index_document = "index.html"
    error_document = "index.html"

    routing_rules = jsonencode(
      [
        {
          "Condition": {
            "KeyPrefixEquals": "login"
          },
          "Redirect": {
            "HostName": var.public.urls.app,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }, {
          "Condition": {
            "KeyPrefixEquals": "leaderboard"
          },
          "Redirect": {
            "HostName": var.public.urls.app,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }, {
          "Condition": {
            "KeyPrefixEquals": "all"
          },
          "Redirect": {
            "HostName": var.public.urls.app,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }, {
          "Condition": {
            "KeyPrefixEquals": "by-vulnerability"
          },
          "Redirect": {
            "HostName": var.public.urls.app,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }, {
          "Condition": {
            "KeyPrefixEquals": "challenges"
          },
          "Redirect": {
            "HostName": var.public.urls.app,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }, {
          "Condition": {
            "KeyPrefixEquals": "profile"
          },
          "Redirect": {
            "HostName": var.public.urls.app,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }, {
          "Condition": {
            "KeyPrefixEquals": "topic/"
          },
          "Redirect": {
            "HostName": var.public.urls.app,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }, {
          "Condition": {
            "KeyPrefixEquals": "challenge"
          },
          "Redirect": {
            "HostName": var.public.urls.app,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }, {
          "Condition": {
            "KeyPrefixEquals": "admin"
          },
          "Redirect": {
            "HostName": var.public.urls.app,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }, {
          "Redirect": {
            "HostName": var.public.urls.www,
            "Protocol": "https",
            "HttpRedirectCode": "301"
          }
        }
      ]
    )
  }
}

resource "aws_s3_bucket" "app" {
  bucket = var.public.urls.app
  acl    = "public-read"
  policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_main",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.public.urls.app}/*",
      "Principal": "*"
    }
  ]
}
EOF
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket" "www" {
  bucket = var.public.urls.www
  acl    = "public-read"
  policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_main",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.public.urls.www}/*",
      "Principal": "*"
    }
  ]
}
EOF
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}
