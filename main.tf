# Already created default VPC 

data "aws_vpc" "myvpc" {
  id = "vpc-03c5f15166413e795"
}

data "aws_subnet" "publicSubnet" {
  id = "subnet-025fabcc149840149"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


data "aws_security_group" "SG-docker" {
  id = "sg-01ee057827c2ed663"

}

# My EC2 instance
resource "aws_instance" "DockerInstance" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.publicSubnet.id
  vpc_security_group_ids      = [data.aws_security_group.SG-docker.id]
  key_name                    = "keyname"
  associate_public_ip_address = "true"

  tags = {
    "Name" = "dockerInstance"
  }
}

# Provisioners for docker image
# Terraform is logging onto the EC2 to run the provisioner files
resource "null_resource" "key" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/keyname.pem")
    host        = aws_instance.DockerInstance.public_ip
  }

  # File being copied to the server
  provisioner "file" {
    source      = "./images/docker-image.sh"
    destination = "/home/ec2-user/docker-image.sh"
  }
  provisioner "file" {
    source = "./images/Dockerfile"
    destination = "/home/ec2-user/Dockerfile"
  }

  # This block runs the script which was being copied onto the server
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/ec2-user/docker-image.sh",
      "bash /home/ec2-user/docker-image.sh"
    ]
  }

  depends_on = [aws_instance.DockerInstance]
}