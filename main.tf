# Infrastructure Deployment for Rust-Agent Project 

provider "aws" { 
  region = "us-west-2" 
} 

# Module for VPC creation

resource "aws_vpc" "rust-vpc" { 
  cidr_block = "10.0.0.0/16" 

  tags = { 
    Name = "Rust VPC" 
  } 
} 

# Module for Public Networks 

resource "aws_subnet" "rust-public-1" { 
  vpc_id     = aws_vpc.rust-vpc.id 
  cidr_block = "10.0.1.0/24" 

  tags = { 
    Name = "Rust-Public-Network-1" 
  }  
} 

resource "aws_subnet" "rust-public-2" { 
  vpc_id     = aws_vpc.rust-vpc.id 
  cidr_block = "10.0.2.0/24" 

  tags = { 
    Name = "Rust-Public-Network-2" 
  }  
} 

# Module for Internet Gateway 

resource "aws_internet_gateway" "rust-igw" { 
  vpc_id = aws_vpc.rust-vpc.id 

  tags = { 
    Name = "Rust-IGW" 
  } 
} 

# Module for Elastic IP for the Nat Gateway 

resource "aws_eip" "rust-eip" { 
  vpc        = true 
  depends_on = [aws_internet_gateway.rust-igw] 
}  

# Module for Route Tables 

resource "aws_route_table" "rust_public_route" { 
  vpc_id = aws_vpc.rust-vpc.id 
  
  route { 
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.rust-igw.id 
  } 

  tags = { 
    Name = "Rust Public Route Table" 
  } 
} 

# Module for Route Tables Associations 

resource "aws_route_table_association" "Public-assoc-rust-1" {  
  subnet_id      = aws_subnet.rust-public-1.id 
  route_table_id = aws_route_table.rust_public_route.id  
} 


resource "aws_route_table_association" "Public-assoc-rust-2" {  
  subnet_id      = aws_subnet.rust-public-2.id 
  route_table_id = aws_route_table.rust_public_route.id  
}  

# Module for Public Key 

resource "aws_key_pair" "rust_keys" {
  key_name   = "rust_agent_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCfoEhhHqZjVKwBQ26UjzIZbxd0W2oYsXsg3wBDRSVj6QAvwdBLJhPmOoa8TkckXZLIEjuxniOqRtROaHqPrOGW0ZLY3kYE87URmM+isB+o4Kt+buKZeGni2gf/KcafL8H+/ag1rvH272XxuIdo6XMqCtL48im/0hD1WuXdnvpljMApFd3yl2aGsLSxLpjzceQ6iboPpPUuSJPodiiQDT5C1F8u+tQVhYxTv50sBdo4w9SYodkg6AVgg/nV+KaHGEegfS/4ofIz5/0nlbBRovCfxAvHCqeVzzKAjQeKHIUUG1xWXZJCeDjKLwihoSvXsJA00YHhle9c0QvIrDjjYYsiB0pbTznd9ODxagtARvmlt/AiEtwg+PKu+E3EvSU0Lk+/qWDN5xhj7DjQcUOQ1wTpqM+3U3TV0MpHnyxCqXWK6Xi5hPeiyaJSBJbuGoDyDcHjwLzF/CrBQ/wgj3ZcTrezjF/hGmnnwVnSAgJrhrDj3hP1vwei7V9Z89ZYauq6Smc= root@941ddda331e1"
}  

# Module for Security Groups 

resource "aws_security_group" "rust_agent_external_access" { 
  name        = "Allow access to Rust Agents" 
  description = "Allow External Access to Rust Hosts"  
  vpc_id      = aws_vpc.rust-vpc.id 
}  

resource "aws_security_group_rule" "rust_ingress_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rust_agent_external_access.id
}  

resource "aws_security_group_rule" "rust_ingress_22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rust_agent_external_access.id
}   

resource "aws_security_group_rule" "rust_ingress_3333" {
  type              = "ingress"
  from_port         = 3333
  to_port           = 3333
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rust_agent_external_access.id
}   

resource "aws_security_group_rule" "rust_ingress_2375" {
  type              = "ingress"
  from_port         = 2375
  to_port           = 2375
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rust_agent_external_access.id
} 

resource "aws_security_group_rule" "rust_agent_egress" { 
  type              = "egress" 
  from_port         = 0 
  to_port           = 0 
  protocol          = "-1"  
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rust_agent_external_access.id  
}

# Module for EC2 Instances 

resource "aws_instance" "rust-host-production" { 
  ami                      = "ami-0c7ea5497c02abcaf" 
  instance_type            = "t3.large"   
  key_name                 = aws_key_pair.rust_keys.id 
  vpc_security_group_ids   = [aws_security_group.rust_agent_external_access.id] 
  subnet_id                = aws_subnet.rust-public-1.id  
  root_block_device { 
    volume_size = 512 
    delete_on_termination = false
  } 

  user_data = file("install.sh")   

  tags = { 
    Name = "Rust Host Production"
  } 

} 

resource "aws_instance" "rust-host-test" { 
  ami                      = "ami-0c7ea5497c02abcaf"  
  instance_type            = "t3.large"   
  key_name                 = aws_key_pair.rust_keys.id 
  vpc_security_group_ids   = [aws_security_group.rust_agent_external_access.id]
  subnet_id                = aws_subnet.rust-public-2.id  
  root_block_device { 
    volume_size = 512 
    delete_on_termination = false
  } 

  user_data = file("install.sh")

  tags = { 
    Name = "Rust Host Test"
  } 

} 

# Module for Instances's Elastic IPs 

resource "aws_eip" "rust-production-instance-eip" { 
  instance          = aws_instance.rust-host-production.id 
  vpc               = true    
  depends_on = [aws_instance.rust-host-production]
} 

resource "aws_eip" "rust-test-instance-eip" { 
  instance          = aws_instance.rust-host-test.id 
  vpc               = true  
}  

# Module for inserting the Public Keys file in production admin user

resource "null_resource" "null_production" {
  connection { 
      type        = "ssh" 
      user        = "admin" 
      private_key = "${file("./private_rust.pem")}"  
      host        = "${aws_eip.rust-production-instance-eip.public_ip}"
    }    

  provisioner "file" {
    source      = "./public_keys_rust" 
    destination = "/home/admin/.ssh/authorized_keys" 
  } 
  depends_on = [aws_eip.rust-production-instance-eip]   
}  

# Module for inserting the Public Keys file in test admin user 

resource "null_resource" "null_test" {
  connection { 
      type        = "ssh" 
      user        = "admin" 
      private_key = "${file("./private_rust.pem")}"  
      host        = "${aws_eip.rust-test-instance-eip.public_ip}"
    }    

  provisioner "file" {
    source      = "./public_keys_rust" 
    destination = "/home/admin/.ssh/authorized_keys" 
  } 
  depends_on = [aws_eip.rust-test-instance-eip]   
}  




  

  






   
  



