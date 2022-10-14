# Specific provider name according to the use case has to given!
provider "aws" {
  
  # Write the region name below in which your environment has to be deployed!
  region = "us-east-1"

  # Assign the profile name here!
  profile = "default"
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
    aws_vpc.Test_VPC
  ]
  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.Test-VPC
  
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
vpc_id = aws_vpc.Test-VPC
  
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
  vpc_id = aws_vpc.Test-VPC
  
  # IP Range of this subnet
  cidr_block = "172.22.1.0/25"
  
  # Data Center of this subnet.
  availability_zone = "us-east-1c"
  
  tags = {
    Name = "Test_Public_Subnet-1c"
  }
}
resource "aws_subnet" "subnet3" {
  depends_on = [
    aws_vpc.Test-VPC,
  ]
  
  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.Test-VPC
  
  # IP Range of this subnet
  cidr_block = "172.22.1.128/25"
  
  # Data Center of this subnet.
  availability_zone = "us-east-1c"
  
  tags = {
    Name = "Test_Public_Subnet-1d"
  }
}
