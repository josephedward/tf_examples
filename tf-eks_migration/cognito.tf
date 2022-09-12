resource "aws_cognito_user_pool" "hackedu" {

  name = var.public.cognito.pool_name

  admin_create_user_config {
    allow_admin_create_user_only = false

    invite_message_template {
      email_message = "Your username is {username} and temporary password is {####}. "
      email_subject = "Your temporary password"
      sms_message   = "Your username is {username} and temporary password is {####}. "
    }
  }

  auto_verified_attributes = ["email"]
  device_configuration {
    challenge_required_on_new_device = false
    device_only_remembered_on_user_prompt = false
  }

  email_configuration {
    email_sending_account  = "DEVELOPER"
    reply_to_email_address = "'HackEDU'<${var.public.email.info}>"
    source_arn             = "arn:aws:ses:us-east-1:${var.public.account_id}:identity/${var.public.email.info}"
  }

  password_policy {
    minimum_length                   = 6
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "TeamName"
    required            = false
    string_attribute_constraints {
      max_length  = 256
      min_length  = 1
    }
  }

  sms_authentication_message = "Your authentication code is {####}. "
  sms_verification_message = "Your verification code is {####}. "

  username_attributes = ["email"]

  verification_message_template {
    default_email_option  = "CONFIRM_WITH_CODE"
    email_subject         = "Your verification code"
    email_subject_by_link = "Welcome to HackEDU! [Action Required]"
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name = "app"
  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "phone",
    "email",
    "openid",
    "profile",
    "aws.cognito.signin.user.admin"
  ]

  callback_urls        = var.public.cognito.callback_url_list
  default_redirect_uri = "/test"
  logout_urls          = sort(var.public.cognito.logout_url_list)

  supported_identity_providers = [
    "COGNITO"
  ]

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      supported_identity_providers
    ]
  }

  user_pool_id = aws_cognito_user_pool.hackedu.id
}

resource "aws_cognito_user_pool_domain" "app" {
  depends_on      = [aws_acm_certificate_validation.auth-validation]
  domain          = var.public.urls.auth
  certificate_arn = aws_acm_certificate.auth.arn
  user_pool_id    = aws_cognito_user_pool.hackedu.id
}

resource "aws_cognito_identity_pool" "app" {
  identity_pool_name               = var.public.cognito.identity_pool_name
  allow_unauthenticated_identities = true

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.app.id
    provider_name           = aws_cognito_user_pool.hackedu.endpoint
    server_side_token_check = false
  }
}
