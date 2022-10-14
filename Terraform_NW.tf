provider "aws" {
        region = "us-east-1"
}
# Creating a VPC!
resource "aws_vpc" "Test-VPC" {

  # IP Range for the VPC
  cidr_block = "172.22.0.0/16"

  # Enabling automatic hostname assigning
  enable_dns_hostnames = true
  tags = {
    Name = "Test-VPC"
  }
}
# Creating Private subnet!
resource "aws_subnet" "subnet1" {
  depends_on = [
    aws_vpc.Test-VPC
  ]
  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.Test-VPC.id

  # IP Range of this subnet
  cidr_block = "172.22.0.0/25"

  # Data Center of this subnet.
  availability_zone = "us-east-1c"

  # Enabling automatic public IP assignment on instance launch!
  map_public_ip_on_launch = true

  tags = {
    Name = "Test_Private_Subnet-1c"
  }
}
# Creating Private subnet!
resource "aws_subnet" "subnet2" {
  depends_on = [
    aws_vpc.Test-VPC
  ]
  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.Test-VPC.id

  # IP Range of this subnet
  cidr_block = "172.22.0.128/25"

  # Data Center of this subnet.
  availability_zone = "us-east-1d"

  # Enabling automatic public IP assignment on instance launch!
  map_public_ip_on_launch = true

  tags = {
    Name = "Test_Private_Subnet-1d"
  }
}
# Creating Public subnet!
resource "aws_subnet" "subnet3" {
  depends_on = [
    aws_vpc.Test-VPC,
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.Test-VPC.id

  # IP Range of this subnet
  cidr_block = "172.22.1.0/25"

  # Data Center of this subnet.
  availability_zone = "us-east-1c"

  tags = {
    Name = "Test_Public_Subnet-1c"
  }
}
resource "aws_subnet" "subnet4" {
  depends_on = [
    aws_vpc.Test-VPC,
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.Test-VPC.id

  # IP Range of this subnet
  cidr_block = "172.22.1.128/25"

  # Data Center of this subnet.
  availability_zone = "us-east-1c"

  tags = {
    Name = "Test_Public_Subnet-1d"
  }
}
# Creating an Internet Gateway for the VPC
resource "aws_internet_gateway" "Test-IGW" {
  depends_on = [
    aws_vpc.Test-VPC,
  ]

  # VPC in which it has to be created!
  vpc_id = aws_vpc.Test-VPC.id
  tags = {
    Name = "Test-IGW"
  }
}
# Creating an Route Table for the Private subnet!
resource "aws_route_table" "Public-Subnet-RT" {
  depends_on = [
    aws_vpc.Test-VPC,
    aws_internet_gateway.Test-IGW
  ]

   # VPC ID
  vpc_id = aws_vpc.Test-VPC.id

  # NAT Rule
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Test-IGW.id
  }

  tags = {
    Name = "Public-Subnet-RT"
  }
}
# Creating a resource for the Route Table Association!
resource "aws_route_table_association" "Public-RT-Association" {

  depends_on = [
#    aws_vpc.VPC-Test,
    aws_subnet.subnet3,
    aws_subnet.subnet4,
    aws_route_table.Public-Subnet-RT
  ]

# Public Subnet ID
  subnet_id      = aws_subnet.subnet3.id

#  Route Table ID
  route_table_id = aws_route_table.Public-Subnet-RT.id
}
# Creating an Elastic IP for the NAT Gateway!
resource "aws_eip" "Test-Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association.Public-RT-Association
  ]
  vpc = true
}
# Creating a NAT Gateway!
resource "aws_nat_gateway" "Test-NAT-GW" {
  depends_on = [
    aws_eip.Test-Nat-Gateway-EIP
  ]

  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.Test-Nat-Gateway-EIP.id

  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.subnet3.id
  tags = {
    Name = "Test-NAT-GW"
  }
}
# Creating a Route Table for the Nat Gateway!
resource "aws_route_table" "Private-subnet-RT" {
  depends_on = [
    aws_nat_gateway.Test-NAT-GW
  ]

  vpc_id = aws_vpc.Test-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Test-NAT-GW.id
  }

  tags = {
    Name = "Private-Subnet-RT"
  }
}
# Creating a Security Group for WordPress
resource "aws_security_group" "WS-SG" {

  depends_on = [
    aws_vpc.Test-VPC,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  description = "HTTP, PING, SSH"

  # Name of the security Group!
  name = "webserver-sg"

  # VPC ID in which Security group has to be created!
  vpc_id = aws_vpc.Test-VPC.id

  # Created an inbound rule for webserver access!
  ingress {
    description = "HTTP for webserver"
    from_port   = 80
    to_port     = 80

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22

    # Here adding tcp instead of ssh, because ssh in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outward Network Traffic for the WordPress
  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Creating security group for MySQL, this will allow access only from the instances having the security group created above.
resource "aws_security_group" "MySQL-SG" {

  depends_on = [
    aws_vpc.Test-VPC,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_security_group.WS-SG
  ]

  description = "MySQL Access only from the Webserver Instances!"
  name = "mysql-sg"
  vpc_id = aws_vpc.Test-VPC.id

  # Created an inbound rule for MySQL
  ingress {
    description = "MySQL Access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.WS-SG.id]
  }

  egress {
    description = "output from MySQL"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Creating security group for Bastion Host/Jump Box
resource "aws_security_group" "BH-SG" {

  depends_on = [
    aws_vpc.Test-VPC,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]

  description = "MySQL Access only from the Webserver Instances!"
  name = "bastion-host-sg"
  vpc_id = aws_vpc.Test-VPC.id

  # Created an inbound rule for Bastion Host SSH
  ingress {
    description = "Bastion Host SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from Bastion Host"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Creating security group for MySQL Bastion Host Access
resource "aws_security_group" "DB-SG-SSH" {

  depends_on = [
    aws_vpc.Test-VPC,
    aws_subnet.subnet1,
    aws_subnet.subnet2,
    aws_security_group.BH-SG
  ]

  description = "MySQL Bastion host access for updates!"
  name = "mysql-sg-bastion-host"
  vpc_id = aws_vpc.Test-VPC.id

  # Created an inbound rule for MySQL Bastion Host
  ingress {
    description = "Bastion Host SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.BH-SG.id]
  }

  egress {
    description = "output from MySQL BH"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
