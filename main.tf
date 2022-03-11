provider "aws" {
  region                  = "eu-west-2"
  profile                 = "Nikola"
}

resource "aws_vpc" "vpc1" {
  cidr_block       = "10.23.0.0/16"
#  enable_dns_hostnames = true

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

resource "aws_autoscaling_group" "asg" {
  name                      = "asg"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.lc.name
  vpc_zone_identifier       = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
}

data "aws_ami" "ubuntu12dddddddd" {
  most_recent = true


  # filter {
  #   name   = "name"
  #   values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"]
  # }

  filter {
    name   = "image-id"
    values = ["ami-0015a39e4b7c0966f"]
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "vpc1ubuntu2" {
  ami           = "ami-0015a39e4b7c0966f"
  instance_type = "t2.micro"
  availability_zone = "eu-west-2a"
  key_name = "nikolaKEY"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.instance1nic.id
  }

	user_data = <<-EOF
                #! /bin/bash     
                sudo apt-get update
                sudo apt-get install -y    apt-transport-https     ca-certificates     curl     gnupg-agent     software-properties-common
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                sudo add-apt-repository \
                 "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
                  $(lsb_release -cs) \
                 stable"  
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                sudo docker build -t hhh:1.0 https://hereismynginxfile.s3.amazonaws.com/Dockerfile
                sudo docker run -p 80:80 -d hhh:1.0
                sudo docker run -d --name mongo-cointainer -e MONGO_INITDB_ROOT_USERNAME=mongoadmin -e MONGO_INITDB_ROOT_PASSWORD=secret mongo
              EOF

  
  tags = {
    Name = "nikola"
  }
}

resource "aws_network_interface" "instance1nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.23.1.50"]
  security_groups = [aws_security_group.allow_web_ssh.id]

}

resource "aws_eip" "instance1eip" {
  vpc                       = true
  network_interface         = aws_network_interface.instance1nic.id
  associate_with_private_ip = "10.23.1.50"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_security_group" "allow_web_ssh" {
  name        = "vpc1-SG1Nikola"
  description = "vpc1 SG1Nikola"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc1 SG1 Nikola"
  }
}