# provider "aws" {
#   region                  = "eu-west-2"
#   profile                 = "Nikola"
# }

terraform {
  backend "s3" {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "eu-west-2"
    dynamodb_table = "tazi-db-e-za-lock"
    encrypt = true
    profile = "Nikola"
  }
}

resource "aws_vpc" "vpc1" {
  cidr_block       = "10.23.0.0/16"

  tags = {
    Name = "NikolaVPC"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.23.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "subnet-1Nikola"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.23.2.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "subnet-2Nikola"
  }
}

data "template_file" "user_data" {
  template = file("user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc1.id
tags = {
    Name = "IGW for vpc1Nikola"
  }
}

resource "aws_route_table" "vpc1route" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "vpc1 route tableNikola"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.vpc1route.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.vpc1route.id
}

resource "aws_autoscaling_group" "asg" {
  name                      = "asg"
  max_size                  = 4
  min_size                  = 2
  # health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  target_group_arns = [aws_lb_target_group.lb_tg.arn]
  launch_configuration      = aws_launch_configuration.lc.name
  vpc_zone_identifier       = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
  
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "ubuntu12dddddddd" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.ami_linux]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "lc" {
  name   = "lc"
  image_id      = data.aws_ami.ubuntu12dddddddd.id
  instance_type = "t2.micro"
  key_name = "nikolaKEY"
  associate_public_ip_address = true
  security_groups = [aws_security_group.allow_web_ssh.id]
  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "allow_web_ssh" {
  name        = "SG Nikola"
  description = "SG Nikola"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "httpd"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG Nikola"
  }
}

resource "aws_lb" "alb" {
  name               = "alb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web_ssh.id]
  subnets            = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
}

resource "aws_lb_target_group" "lb_tg" {
    health_check {
      interval = 10
      path = "/"
      protocol = "HTTP"
      timeout = 5
      matcher = 200
    }
  name     = "lb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id
}

resource "aws_lb_listener" "listener_group" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    # port = "8080"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

resource "aws_lb_listener_rule" "lb_rule" {
  listener_arn = aws_lb_listener.listener_group.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "tozi-bucket-e-za-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "eu-west-2"
    profile = "Nikola"
  }
}