
############################################
#               PROVIDER
############################################
provider "aws" {
  region     = var.aws_region
  //shared_credentials_file = var.aws_path_creds
  //profile                 = var.aws_profile
  version = "~> 3.2"
}

############################################
#               VARS
############################################

variable "aws_region" {
    default = "sa-east-1"
}

variable "aws_path_creds" {
    default = "$HOME/.aws/credentials"
}

variable "aws_profile" {
    default = "lab"
}

variable "machine_type" {
    default = "t3.micro"
}

############################################
#               LOCALS VARS
############################################

locals {                                                            
  subnet_ids_string = join(",", data.aws_subnet_ids._.ids)
  subnet_ids_list = split(",", local.subnet_ids_string)             
}


############################################
#               DATA SOURCES
############################################
data "aws_vpcs" "foo" {}

data "aws_vpc" "foo" {
  count = length(data.aws_vpcs.foo.ids)
  id    = tolist(data.aws_vpcs.foo.ids)[count.index]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_subnet_ids" "_" {
  vpc_id = data.aws_vpc.foo[1].id
}

data "aws_subnet" "_" {
  for_each = data.aws_subnet_ids._.ids
  id       = each.value
}

############################################
#               RESOURCES
############################################
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  //for_each      = data.aws_subnet_ids._.ids
  instance_type = var.machine_type
  //subnet_id = each.value
  subnet_id = element(local.subnet_ids_list,0)

  tags = {
    Name = "tf-machine"
  }
}

############################################
#               OUTPUTS
############################################
output "subnet_cidr_blocks" {
  value = [for s in data.aws_subnet._ : s.cidr_block]
}

output "foo" {
  value = data.aws_vpcs.foo.ids
}