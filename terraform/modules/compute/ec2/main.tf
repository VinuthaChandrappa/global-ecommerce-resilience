resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Allow HTTP and SSH"

  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "web_template" {

  name_prefix   = "ecommerce-template"
  image_id      = "ami-0892d3c7ee96c0bf7"
  instance_type = "t2.micro"

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      aws_security_group.web_sg.id
    ]
  }

  user_data = base64encode(<<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>E-Commerce Backend Running</h1>" | sudo tee /var/www/html/index.html
EOF
)
}
resource "aws_lb_target_group" "web_tg" {
  name     = "ecommerce-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
  path                = "/"
  port                = "80"
  healthy_threshold   = 3
  unhealthy_threshold = 3
  timeout             = 5
  interval            = 30
  matcher             = "200"
}
}
resource "aws_lb" "web_alb" {
  name               = "ecommerce-alb"
  load_balancer_type = "application"
  subnets = [
  var.public_subnet_1_id,
  var.public_subnet_2_id
]
  security_groups = [
    aws_security_group.web_sg.id
  ]
}
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  vpc_zone_identifier = [
  var.public_subnet_1_id,
  var.public_subnet_2_id
]

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.web_tg.arn
  ]

  health_check_type = "ELB"
}