provider "aws" {
	region = "us-east-1"
	}
	
resource "aws_vpc" "Test_VPC" {
  cidr_block       = "172.22.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Test_VPC"
  }
}
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.Test_VPC.id
  cidr_block = "172.22.0.0/25"
  availability_zone = "us-east-1c"

  tags = {
    Name = "Test_Private_Subnet-1c"
  }
}
resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.Test_VPC.id
  cidr_block = "172.22.0.128/25"
  availability_zone = "us-east-1d"

  tags = {
    Name = "Test_Private_Subnet-1d"
  }
}
resource "aws_subnet" "subnet3" {
  vpc_id     = aws_vpc.Test_VPC.id
  cidr_block = "172.22.1.0/25"
  availability_zone = "us-east-1c"

  tags = {
    Name = "Test_Public_Subnet-1c"
  }
}
resource "aws_subnet" "subnet4" {
  vpc_id     = aws_vpc.Test_VPC.id
  cidr_block = "172.22.1.128/25"
  availability_zone = "us-east-1d"

  tags = {
    Name = "Test_Public_Subnet-1d"
  }
}
resource "aws_internet_gateway" "Internet_Gateway" {
  depends_on = [
    aws_vpc.Test_VPC,
    aws_subnet.subnet3
  ]

  # VPC in which it has to be created!
  vpc_id = aws_vpc.Test_VPC.id

  tags = {
    Name = "Test_IGW"
  }
}
resource "aws_route_table" "Public-Subnet-RT" {
  depends_on = [
    aws_vpc.Test_VPC,
    aws_internet_gateway.Internet_Gateway
  ]

   # VPC ID
  vpc_id = aws_vpc.Test_VPC.id

  # NAT Rule
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway.id
  }

  tags = {
    Name = "Test-Public_Subnet-RT"
  }
}
resource "aws_route_table_association" "Public-RT-Association" {

  depends_on = [
    aws_vpc.Test_VPC,
    aws_subnet.subnet3,
    aws_route_table.Public-Subnet-RT
  ]

# Public Subnet ID
  subnet_id      = "subnet-074e2ab67e4dfb0ab"

#  Route Table ID
  route_table_id = aws_route_table.Public-Subnet-RT.id
}
resource "aws_route_table_association" "Public-RT-Association1" {

  depends_on = [
    aws_vpc.Test_VPC,
    aws_subnet.subnet4,
    aws_route_table.Public-Subnet-RT
  ]

# Public Subnet ID
  subnet_id      = "subnet-0bbff7bb7cff10d39"

#  Route Table ID
  route_table_id = aws_route_table.Public-Subnet-RT.id
}
resource "aws_eip" "Test-Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association.Public-RT-Association
  ]
  vpc = true
}
resource "aws_nat_gateway" "Test-NAT_GATEWAY" {
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
resource "aws_route_table" "Private-Subnet-RT" {
  depends_on = [
    aws_nat_gateway.Test-NAT_GATEWAY
  ]

  vpc_id = aws_vpc.Test_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Test-NAT_GATEWAY.id
  }

  tags = {
    Name = "Test-Private_Subnet-RT"
  }

}
resource "aws_route_table_association" "Private-RT-Association" {

  depends_on = [
    aws_vpc.Test_VPC,
    aws_subnet.subnet1,
    aws_route_table.Private-Subnet-RT
  ]

# Private Subnet ID
  subnet_id      = aws_subnet.subnet1.id

#  Route Table ID
  route_table_id = aws_route_table.Private-Subnet-RT.id
}
resource "aws_route_table_association" "Private-RT-Association-1" {

  depends_on = [
    aws_vpc.Test_VPC,
    aws_subnet.subnet2,
    aws_route_table.Private-Subnet-RT
  ]

# Private Subnet ID
  subnet_id      = aws_subnet.subnet2.id

#  Route Table ID
  route_table_id = aws_route_table.Private-Subnet-RT.id
}
resource "aws_security_group" "Test-Webserver-SG" {

  depends_on = [
    aws_vpc.Test_VPC,
  ]

  description = "HTTP, PING, SSH"

  # Name of the security Group!
  name = "Test-Webserver-sg"
  tags = {
    Name = "Test-Webserver-sg"
  }
  # VPC ID in which Security group has to be created!
  vpc_id = aws_vpc.Test_VPC.id

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
resource "aws_security_group" "Test-MySQL-SG" {

  depends_on = [
    aws_vpc.Test_VPC,
  ]

  description = "MySQL Access only from the Webserver Instances!"
  name = "Test-MySQL-sg"
  tags = {
    Name = "Test-MySQL-sg"
  }
  vpc_id = aws_vpc.Test_VPC.id

  # Created an inbound rule for MySQL
  ingress {
    description = "MySQL Access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.Test-Webserver-SG.id]
  }

  egress {
    description = "output from MySQL"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "Test-BH-SG" {

  depends_on = [
    aws_vpc.Test_VPC,
]
  description = "MySQL Access only from the Webserver Instances!"
  name = "Test-BH-SG"
  tags = {
    Name = "Test-BH-SG"
  }
  vpc_id = aws_vpc.Test_VPC.id

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
resource "aws_security_group" "Test-DB-SG-SSH" {

  depends_on = [
    aws_vpc.Test_VPC,
  ]

  description = "MySQL Bastion host access for updates!"
  name = "Test-DB-SG-SSH"
  tags = {
    Name = "Test-DB-SG-SSH"
  }
  vpc_id = aws_vpc.Test_VPC.id

  # Created an inbound rule for MySQL Bastion Host
  ingress {
    description = "Bastion Host SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.Test-BH-SG.id]
  }

  egress {
    description = "output from MySQL BH"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "Test-webserver" {

  depends_on = [
    aws_vpc.Test_VPC,
]

  # AMI ID [I have used my custom AMI which has some softwares pre installed]
  ami = "ami-026b57f3c383c2eec"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet3.id

  # Keyname and security group are obtained from the reference of their instances created above!
  # Here I am providing the name of the key which is already uploaded on the AWS console.
  key_name = "Terraform"

  # Security groups to use!
  vpc_security_group_ids = ["sg-09d32f06c6750440e"]

  tags = {
   Name = "Test-Webserver"
  }

  # Code for installing the softwares!
  provisioner "remote-exec" {
    inline = [
        "sudo yum update -y",
        "sudo yum install php php-mysqlnd httpd -y",
        "wget https://wordpress.org/wordpress-4.8.14.tar.gz",
        "tar -xzf wordpress-4.8.14.tar.gz",
        "sudo cp -r wordpress /var/www/html/",
        "sudo chown -R apache.apache /var/www/html/",
        "sudo systemctl start httpd",
        "sudo systemctl enable httpd",
        "sudo systemctl restart httpd"
    ]
  }
}
resource "aws_instance" "Test-MySQL" {
  # Using my custom Private AMI which has most of the things configured for WordPress
  # i.e. MySQL Installed!
  ami = "ami-026b57f3c383c2eec"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id

  # Keyname and security group are obtained from the reference of their instances created above!
  key_name = "Terraform"

  # Attaching 2 security groups here, 1 for the MySQL Database access by the Web-servers,
  # & other one for the Bastion Host access for applying updates & patches!
  vpc_security_group_ids = ["sg-0b68101d3f2c8fdaf"]

  tags = {
   Name = "Test-MySQL"
  }
}
