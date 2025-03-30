provider "aws" {
  region = "us-east-1"
}

# Define the IAM role
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "EC2S3AccessRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the S3 full access policy to the role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create an instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_s3_access_role.name
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name                   = "single-instance"
  instance_type          = "t3.small"
  key_name               = "my-key" # Substitua pelo nome da sua chave SSH <<<<<<<<<<<
  vpc_security_group_ids = [aws_security_group.ec2_k6_sg.id]
  subnet_id              = "subnet-123456" # ID da sub-rede desejada <<<<<<<<<<
  ami                    = "ami-084568db4383264d4"

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
            #!/bin/bash
            sudo apt-get update -y

            sudo gpg -k
            sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
            echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
            sudo apt-get update
            sudo apt-get install k6

            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            sudo apt install unzip
            unzip awscliv2.zip
            sudo ./aws/install
            EOF

  tags = {
    Name = "k6-vm"
  }
}


resource "aws_security_group" "ec2_k6_sg" {
  name        = "ec2-k6-sg"
  description = "Permite saida para a internet e acesso a rede interna"
  vpc_id      = "vpc-xxx" # Substitua pelo ID da sua VPC <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  tags = {
    Name = "ec2-k6-sg"
  }
}

# Saída para HTTP
resource "aws_vpc_security_group_egress_rule" "http_out" {
  security_group_id = aws_security_group.ec2_k6_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Saída para HTTPS
resource "aws_vpc_security_group_egress_rule" "https_out" {
  security_group_id = aws_security_group.ec2_k6_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Saída para a rede interna da VPC (ajuste se sua VPC for diferente)
resource "aws_vpc_security_group_egress_rule" "vpc_internal_out" {
  security_group_id = aws_security_group.ec2_k6_sg.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1" # Tudo (TCP, UDP, ICMP, etc.)
}

output "instance_public_dns" {
  description = "The public DNS of the EC2 instance"
  value       = module.ec2_instance.public_dns
}
