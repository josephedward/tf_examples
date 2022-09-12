resource "aws_ecr_repository" "api-sandbox" {
  name = "api-sandbox"
}

resource "aws_ecr_repository" "proxy-http" {
  name = "proxy-http"
}

resource "aws_ecr_repository" "proxy-socketio" {
  name = "proxy-socketio"
}

resource "aws_ecr_repository" "temp" {
  name = "temp"
}
