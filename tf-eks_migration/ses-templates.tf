resource "aws_ses_template" "reminder_initial" {
  name    = "reminder_initial"
  subject = "You have been assigned new security training"

  html = <<EMAIL
<html>
<head><title>HackEDU Training Assignment</title>
</head>
<body>
<p><strong>Training Assignment</strong></p>
<p>You have been assigned the following lessons on HackEDU, which are due by {{phase_end_date}}:</p>
<p>{{content_list}}</p>
<p>You can access all of your training from your <a href="${var.public.urls.app_full}">HackEDU Dashboard</a>.</p>
<p>
  Cheers,<br />
  The HackEDU Team
</p>
<p>You can opt-out of these reminder emails here:  <a href="${var.public.api-hacker.url}/profile/reminder-opt-out?token={{hacker_uuid}}">Unsubscribe</a>.</p>
</body>
</html>
EMAIL
}

resource "aws_ses_template" "reminder_standard" {
  name    = "reminder_standard"
  subject = "Security training reminder (HackEDU)"

  html = <<EMAIL
<html>
<head><title>HackEDU Training Reminder</title>
</head>
<body>
<p><strong>Training Reminder</strong></p>
<p>You have not completed the following lessons on HackEDU, which are due by {{phase_end_date}}:</p>
<p>{{content_list}}</p>
<p>You can access all of your training from your <a href="${var.public.urls.app_full}">HackEDU Dashboard</a>.</p>
<p>
  Cheers,<br />
  The HackEDU Team
</p>
<p>You can opt-out of these reminder emails here:  <a href="${var.public.api-hacker.url}/profile/reminder-opt-out?token={{hacker_uuid}}">Unsubscribe</a>.</p>
</body>
</html>
EMAIL
}

resource "aws_ses_template" "reminder_final" {
  name    = "reminder_final"
  subject = "Final security training reminder (HackEDU)"

  html = <<EMAIL
<html>
<head><title>HackEDU Final Training Reminder</title>
</head>
<body>
<p><strong>Training Reminder</strong></p>
<p>Today is your last day to complete the following lessons on HackEDU:</p>
<p>{{content_list}}</p>
<p>You can access all of your training from your <a href="${var.public.urls.app_full}">HackEDU Dashboard</a>.</p>
<p>
  Cheers,<br />
  The HackEDU Team
</p>
<p>You can opt-out of these reminder emails here:  <a href="${var.public.api-hacker.url}/profile/reminder-opt-out?token={{hacker_uuid}}">Unsubscribe</a>.</p>
</body>
</html>
EMAIL
}

resource "aws_ses_template" "reminder_summary" {
  name    = "reminder_summary"
  subject = "HackEDU Training Summary"

  html = <<EMAIL
<html>
<head><title>HackEDU Training Summary</title>
</head>
<body>
<p><strong>Training Summary</strong></p>
<p>Your team's training plan is complete!</p>
<p><a href="${var.public.urls.app_full}/admin/{{organization_uuid}}/users">View your team's progress in your Admin Dashboard.</a></p>
<p>
  Cheers,<br />
  The HackEDU Team
</p>
</body>
</html>
EMAIL
}
