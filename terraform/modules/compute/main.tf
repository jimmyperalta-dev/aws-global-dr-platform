# terraform/modules/compute/main.tf

# Data source for the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script for web server setup
locals {
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    
    # Create a simple web page
    cat > /var/www/html/index.html << 'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>AWS Global DR Platform - ${var.environment}</title>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                margin: 40px; 
                background-color: #f0f0f0; 
            }
            .container { 
                background-color: white; 
                padding: 20px; 
                border-radius: 8px; 
                box-shadow: 0 2px 4px rgba(0,0,0,0.1); 
            }
            .header { 
                color: #232F3E; 
                border-bottom: 2px solid #FF9900; 
                padding-bottom: 10px; 
            }
            .status { 
                background-color: #d4edda; 
                border: 1px solid #c3e6cb; 
                color: #155724; 
                padding: 10px; 
                border-radius: 4px; 
                margin: 20px 0; 
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1 class="header">🌍 AWS Global Disaster Recovery Platform</h1>
            <div class="status">
                <strong>Status:</strong> ✅ ${upper(var.environment)} Region Active
            </div>
            <p><strong>Environment:</strong> ${var.environment}</p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
            <p><strong>Region:</strong> ${var.aws_region}</p>
            <p><strong>Timestamp:</strong> <span id="timestamp"></span></p>
        </div>
        
        <script>
            // Get instance metadata
            fetch('http://169.254.169.254/latest/meta-data/instance-id')
                .then(response => response.text())
                .then(data => document.getElementById('instance-id').innerText = data)
                .catch(err => document.getElementById('instance-id').innerText = 'Unable to fetch');
            
            fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
                .then(response => response.text())
                .then(data => document.getElementById('az').innerText = data)
                .catch(err => document.getElementById('az').innerText = 'Unable to fetch');
            
            document.getElementById('timestamp').innerText = new Date().toLocaleString();
        </script>
    </body>
    </html>
HTML

    # Create health check endpoint
    cat > /var/www/html/health << 'HEALTH'
    OK
HEALTH

    # Restart httpd to ensure all changes take effect
    systemctl restart httpd
  EOF
  )
}

# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.ec2_security_group_id]

  user_data = local.user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-web-server"
      Environment = var.environment
      Project     = "aws-global-dr-platform"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.environment}-launch-template"
    Environment = var.environment
    Project     = "aws-global-dr-platform"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
    Project     = "aws-global-dr-platform"
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-tg"
    Environment = var.environment
    Project     = "aws-global-dr-platform"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${var.environment}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "aws-global-dr-platform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
