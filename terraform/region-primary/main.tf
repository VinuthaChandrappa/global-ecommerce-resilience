provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../modules/networking/vpc"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_1_cidr = "10.0.1.0/24"
  public_subnet_2_cidr = "10.0.2.0/24"
  private_subnet_cidr  = "10.0.3.0/24"
}
module "ec2" {

  source = "../modules/compute/ec2"

  vpc_id = module.vpc.vpc_id

  public_subnet_1_id = module.vpc.public_subnet_1_id
  public_subnet_2_id = module.vpc.public_subnet_2_id
}