provider "aws" {
  region = "us-east-2"
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
  instance_type          = "t3.large" # Ou o tipo de instância desejado
  key_name               = "my-key"    # Substitua pelo nome da sua chave SSH
  vpc_security_group_ids = ["sg-123456"] # Referência ao output do módulo EKS
  subnet_id              = "subnet-123456" # ID da sub-rede desejada
  ami                    = "ami-0862be96e41dcbf74"

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
            #!/bin/bash
            sudo apt-get update -y
            sudo apt-get install -y python3-pip
            sudo apt install python3-locust -y

            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            sudo apt install unzip
            unzip awscliv2.zip
            sudo ./aws/install
            EOF

  tags = {
    Name = "locust-vm"
  }

}

output "instance_public_dns" {
  description = "The public DNS of the EC2 instance"
  value       = module.ec2_instance.public_dns
}
