resource "aws_ecs_cluster" "content-web" {
  name = "production-was"
}

resource "aws_launch_configuration" "content-web" {
  name          = "content-web"
  image_id      = "ami-0128839b21d19300e"
  instance_type = "t2.large"

  security_groups = [
    aws_security_group.ssh-internal.id,
    aws_security_group.production-ecs-instance.id,
    aws_security_group.static-egress.id
  ]

  iam_instance_profile        = aws_iam_instance_profile.ecs-instance.id
  key_name                    = aws_key_pair.general.id
  associate_public_ip_address = false
  user_data                   = <<DATA
#cloud-boothook
PROXY_HOST=tinyproxy.hackedu.dev
PROXY_PORT=8888
CLUSTER_NAME=production-was

# block metadata service
sudo yum install iptables-services -y
sudo /sbin/iptables -t nat -I PREROUTING -p tcp -d 169.254.169.254 --dport 80 -j DNAT --to-destination 1.1.1.1
systemctl enable iptables && systemctl start iptables

# Configure Yum, the Docker daemon, and the ECS agent to use an HTTP proxy
# Specify proxy host, port number, and ECS cluster name to use
if grep -q 'Amazon Linux release 2' /etc/system-release ; then
    OS=AL2
    echo "Setting OS to Amazon Linux 2"
elif grep -q 'Amazon Linux AMI' /etc/system-release ; then
    OS=ALAMI
    echo "Setting OS to Amazon Linux AMI"
else
    echo "This user data script only supports Amazon Linux 2 and Amazon Linux AMI."
fi

# Set Yum HTTP proxy
if [ ! -f /var/lib/cloud/instance/sem/config_yum_http_proxy ]; then
    echo "proxy=http://$PROXY_HOST:$PROXY_PORT" >> /etc/yum.conf
    echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_yum_http_proxy
fi

# Set Docker HTTP proxy (different methods for Amazon Linux 2 and Amazon Linux AMI)
# Amazon Linux 2
if [ $OS == "AL2" ] && [ ! -f /var/lib/cloud/instance/sem/config_docker_http_proxy ]; then
    mkdir /etc/systemd/system/docker.service.d
    cat <<EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://$PROXY_HOST:$PROXY_PORT/"
Environment="HTTPS_PROXY=http://$PROXY_HOST:$PROXY_PORT/"
Environment="NO_PROXY=169.254.169.254,169.254.170.2"
EOF
    systemctl daemon-reload
    if [ "$(systemctl is-active docker)" == "active" ]
    then
        systemctl restart docker
    fi
    echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_docker_http_proxy
fi

# Amazon Linux AMI
if [ $OS == "ALAMI" ] && [ ! -f /var/lib/cloud/instance/sem/config_docker_http_proxy ]; then
    echo "export HTTP_PROXY=http://$PROXY_HOST:$PROXY_PORT/" >> /etc/sysconfig/docker
    echo "export HTTPS_PROXY=http://$PROXY_HOST:$PROXY_PORT/" >> /etc/sysconfig/docker
    echo "export NO_PROXY=169.254.169.254,169.254.170.2" >> /etc/sysconfig/docker
    echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_docker_http_proxy
fi

# Set ECS agent HTTP proxy
if [ ! -f /var/lib/cloud/instance/sem/config_ecs-agent_http_proxy ]; then
    cat <<EOF > /etc/ecs/ecs.config
ECS_CLUSTER=$CLUSTER_NAME
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true
ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=1h
ECS_IMAGE_PULL_BEHAVIOR=once
ECS_INSTANCE_ATTRIBUTES={"task_role_enabled": "true"}
HTTP_PROXY=$PROXY_HOST:$PROXY_PORT
HTTPS_PROXY=$PROXY_HOST:$PROXY_PORT
NO_PROXY=169.254.169.254,169.254.170.2,/var/run/docker.sock
EOF
    echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_ecs-agent_http_proxy
fi

# Set ecs-init HTTP proxy (different methods for Amazon Linux 2 and Amazon Linux AMI)
# Amazon Linux 2
if [ $OS == "AL2" ] && [ ! -f /var/lib/cloud/instance/sem/config_ecs-init_http_proxy ]; then
    mkdir /etc/systemd/system/ecs.service.d
    cat <<EOF > /etc/systemd/system/ecs.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=$PROXY_HOST:$PROXY_PORT/"
Environment="NO_PROXY=169.254.169.254,169.254.170.2,/var/run/docker.sock"
EOF
    systemctl daemon-reload
    if [ "$(systemctl is-active ecs)" == "active" ]; then
        systemctl restart ecs
    fi
    echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_ecs-init_http_proxy
fi

# Amazon Linux AMI
if [ $OS == "ALAMI" ] && [ ! -f /var/lib/cloud/instance/sem/config_ecs-init_http_proxy ]; then
    cat <<EOF > /etc/init/ecs.override
env HTTP_PROXY=$PROXY_HOST:$PROXY_PORT
env NO_PROXY=169.254.169.254,169.254.170.2,/var/run/docker.sock
EOF
    echo "$$: $(date +%s.%N | cut -b1-13)" > /var/lib/cloud/instance/sem/config_ecs-init_http_proxy
fi
DATA

  root_block_device {
    volume_size = 256
  }

  ebs_block_device {
    device_name = "/dev/xvdcz"
    volume_size = 64
  }
}

resource "aws_autoscaling_group" "content-web" {
  name                      = "content-web"
  min_size                  = var.public.ecs-was.min_size
  max_size                  = var.public.ecs-was.max_size
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.content-web.name
  vpc_zone_identifier       = [
    aws_subnet.private-a.id,
    aws_subnet.private-b.id,
    aws_subnet.private-c.id
  ]
  protect_from_scale_in     = true
  wait_for_capacity_timeout = "0"

  tags = [
    {
      key                 = "Name"
      value               = "ecs-content-was"
      propagate_at_launch = "1"
    }
  ]
}

resource "aws_autoscaling_policy" "content-web-add-instance" {
  name                   = "content-web-add-instance"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.content-web.name
}

resource "aws_cloudwatch_metric_alarm" "content-web-memory-warning" {
  alarm_name = "content-web-memory-warning"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  period = 60
  metric_name = "MemoryReservation"
  namespace = "AWS/ECS"
  statistic = "Average"
  threshold = "70"

  alarm_actions = [
    aws_autoscaling_policy.content-web-add-instance.arn
  ]

  dimensions = {
    ClusterName = "production-was"
  }
}
