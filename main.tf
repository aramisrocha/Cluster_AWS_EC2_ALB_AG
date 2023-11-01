terraform {
  backend "s3" {
    bucket = "aramis-aws-terraform-remote-state-dev"
    key    = "ec2/ec2provider.tfstate"
    region = "us-east-2"
  }
}




provider "aws" {
  region = "${var.region}"
}



# Criando os recursos de rede


resource "aws_vpc" "vpc_LAB" {
    cidr_block =  var.network_cidr
    enable_dns_hostnames = true
}




resource "aws_subnet" "Subnet_LAB" {
  count           = var.subnet_count
  vpc_id          = aws_vpc.vpc_LAB.id
  cidr_block      = cidrsubnet(var.network_cidr, 8, count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index % 2)
}


# Adicionando um security group para acesso ao WEB

resource "aws_security_group" "SG_WEB" {
  name        = "Security group para os servidores WEB"
  description = "Permitit somente acesso a WEB"
  vpc_id      = aws_vpc.vpc_LAB.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
   ingress {
    from_port   = 80
    to_port     = 80
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


  resource "aws_internet_gateway" "Gateway_LAB" {
  vpc_id = aws_vpc.vpc_LAB.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_LAB.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Gateway_LAB.id
  }
}

resource "aws_route_table_association" "public_subnet" {
  count = var.subnet_count
  subnet_id      = aws_subnet.Subnet_LAB[count.index].id
  route_table_id = aws_route_table.public.id
  depends_on     = [aws_internet_gateway.Gateway_LAB]
}