terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}

# 1. CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ec2_log_group" {
  name              = "/ec2/my-app"
  retention_in_days = 30
}

# 2. CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "ec2_log_stream" {
  name           = "instance-log-stream"
  log_group_name = aws_cloudwatch_log_group.ec2_log_group.name
}

# 3. IAM Role for CloudWatch
resource "aws_iam_role" "cloudwatch_role" {
  name = "cloudwatch-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}


# 4. IAM Policy for Logging
resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "cloudwatch-log-policy"
  description = "Permissions for EC2 to send logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "${aws_cloudwatch_log_group.ec2_log_group.arn}:*"
      },
      {
        Action   = "cloudwatch:PutMetricData",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# 5. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

# 6. IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-cloudwatch-profile"
  role = aws_iam_role.cloudwatch_role.name
}

data "aws_ami" "debian_bookworm" {
  most_recent = true
  owners      = ["136693071363"] # Official Debian AMI owner ID

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"] # Adjust the pattern as needed (e.g., debian-11-amd64-*)
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "monitored_ec2" {
  ami                  = data.aws_ami.debian_bookworm.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    # Install dependencies
    apt-get update
    apt-get install -y curl gnupg2
    
    # Add CloudWatch agent repo
    curl -sL https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb -O
    dpkg -i -E ./amazon-cloudwatch-agent.deb
    
    # Create config file
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<-EOL
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/syslog",
                "log_group_name": "${aws_cloudwatch_log_group.ec2_log_group.name}",
                "log_stream_name": "${aws_cloudwatch_log_stream.ec2_log_stream.name}",
                "timestamp_format": "%b %d %H:%M:%S"
              }
            ]
          }
        }
      }
    }
    EOL
    
    # Start CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  EOF
  tags = {
    Name = "CloudWatch-Monitored-Instance"
  }
}

# 8a. CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = "80" # 80% CPU
  alarm_description   = "EC2 CPU utilization exceeds 80%"
  actions_enabled     = true

  dimensions = {
    InstanceId = aws_instance.monitored_ec2.id
  }
}

# 8b. Error Rate Alarm (Example: HTTP 5xx errors)
resource "aws_cloudwatch_metric_alarm" "high_errors" {
  alarm_name          = "high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5xxErrorCount"
  namespace           = "MyApp"
  period              = "300" # 5 minutes
  statistic           = "Sum"
  threshold           = "10" # 10 errors in 5 minutes
  alarm_description   = "High HTTP server error rate detected"
  actions_enabled     = true
}