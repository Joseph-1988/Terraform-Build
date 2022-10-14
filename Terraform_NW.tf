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
