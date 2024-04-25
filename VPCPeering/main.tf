# Create VPC1
resource "aws_vpc" "nv_vpc1" {
  cidr_block = "10.0.0.0/16"
}

# Create internet gateway
resource "aws_internet_gateway" "nv_igw1" {
  vpc_id = aws_vpc.nv_vpc1.id
}

# Create public subnet
resource "aws_subnet" "public_subnet_vpc1" {
  vpc_id            = aws_vpc.nv_vpc1.id
  cidr_block        = "10.0.0.0/24"
  map_public_ip_on_launch = true
}

# Create route table
resource "aws_route_table" "nv_public_route_table1" {
  vpc_id = aws_vpc.nv_vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nv_igw1.id
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet_vpc1.id
  route_table_id = aws_route_table.nv_public_route_table1.id
}

# Create private subnet in VPC 1
resource "aws_subnet" "private_subnet_vpc1" {
  vpc_id            = aws_vpc.nv_vpc1.id
  cidr_block        = "10.0.1.0/24"
}



# Create route table for private subnet in VPC 1

resource "aws_route_table" "route_table_vpc1_private" {
  vpc_id = aws_vpc.nv_vpc1.id
}

# Associate private subnet in VPC 1 with route table

resource "aws_route_table_association" "private_subnet_association_vpc1" {
  subnet_id      = aws_subnet.private_subnet_vpc1.id
  route_table_id = aws_route_table.route_table_vpc1_private.id
}


# Create security group
resource "aws_security_group" "nv_sg_vpc1" {
  name        = "nv_sg_vpc1"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.nv_vpc1.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 #key set up

resource "tls_private_key" "nvkey1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_file1" {
  filename = "nv-public-key2.pem"
  content  = tls_private_key.nvkey1.private_key_pem
}

resource "aws_key_pair" "nv_public_key1" {
  key_name   = "nv-public-key2"
  public_key = tls_private_key.nvkey1.public_key_openssh
}


# Create EC2 instance in public subnet VPC1
resource "aws_instance" "nv_instance1" {
  ami           = "ami-07355fe79b493752d"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_vpc1.id
  key_name               = aws_key_pair.nv_public_key1.id
  vpc_security_group_ids = [aws_security_group.nv_sg_vpc1.id]


  provisioner "local-exec" {
   command = "chmod  400 ${local_file.private_key_file1.filename}"
  }

  provisioner "file" {
    source = "script.sh"
    destination = "/tmp/script.sh"
  }

  connection {
    type = "ssh"
    user = "ec2-user"
    password = ""
    private_key = local_file.private_key_file1.content
    host = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/script.sh"
      # "sudo /tmp/script.sh"
    ]
  }
  
}


# Create EC2 instance in private subnet VPC1


resource "aws_instance" "nv_privateinstance1" {
  ami           = "ami-07355fe79b493752d"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_vpc1.id
  key_name               = aws_key_pair.nv_public_key1.id
  vpc_security_group_ids = [aws_security_group.nv_sg_vpc1.id]


  user_data = <<-EOF
        #!/bin/bash
        yum install -y mysql56-server
       EOF
  
}


############################



# Create VPC2
resource "aws_vpc" "nv_vpc2" {
  cidr_block = "192.168.0.0/16"
}
# Create internet gateway
resource "aws_internet_gateway" "nv_igw2" {
  vpc_id = aws_vpc.nv_vpc2.id
}
# Create public subnet
resource "aws_subnet" "public_subnet_vpc2" {
  vpc_id            = aws_vpc.nv_vpc2.id
  cidr_block        = "192.168.0.0/24"
  map_public_ip_on_launch = true
}
# Create route table
resource "aws_route_table" "nv_public_route_table2" {
  vpc_id = aws_vpc.nv_vpc2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nv_igw2.id
  }
}
# Associate route table with public subnet
resource "aws_route_table_association" "public_route_association2" {
  subnet_id      = aws_subnet.public_subnet_vpc2.id
  route_table_id = aws_route_table.nv_public_route_table2.id
}
# Create security group
resource "aws_security_group" "nv_sg_vpc2" {
  name        = "nv_sg_vpc2"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.nv_vpc2.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 #key set up

resource "tls_private_key" "nvkey2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_file2" {
  filename = "nv-public-key3.pem"
  content  = tls_private_key.nvkey2.private_key_pem
}

resource "aws_key_pair" "nv_public_key2" {
  key_name   = "nv-public-key3"
  public_key = tls_private_key.nvkey2.public_key_openssh
}


# Create private subnet in VPC 2
resource "aws_subnet" "private_subnet_vpc2" {
  vpc_id            = aws_vpc.nv_vpc2.id
  cidr_block        = "192.168.1.0/24"
}

# Create route table for private subnet in VPC 2

resource "aws_route_table" "route_table_vpc2_private" {
  vpc_id = aws_vpc.nv_vpc2.id
}
# Associate private subnet in VPC 2 with route table

resource "aws_route_table_association" "private_subnet_association_vpc2" {
  subnet_id      = aws_subnet.private_subnet_vpc2.id
  route_table_id = aws_route_table.route_table_vpc2_private.id
}

# Create EC2 instance
resource "aws_instance" "nv_instance2" {
  ami           = "ami-07355fe79b493752d"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_vpc2.id
  key_name               = aws_key_pair.nv_public_key2.id
  vpc_security_group_ids = [aws_security_group.nv_sg_vpc2.id]

    provisioner "local-exec" {
   command = "chmod  400 ${local_file.private_key_file2.filename}"
  }


  provisioner "file" {
    source = "script.sh"
    destination = "/tmp/script.sh"
  }

  connection {
    type = "ssh"
    user = "ec2-user"
    password = ""
    private_key = local_file.private_key_file2.content
    host = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/script.sh"
        #"sudo /tmp/script.sh"
    ]
  }
  
}



# Create EC2 instance in private subnet VPC1


resource "aws_instance" "nv_privateinstance2" {
  ami           = "ami-07355fe79b493752d"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_vpc2.id
  key_name               = aws_key_pair.nv_public_key2.id
  vpc_security_group_ids = [aws_security_group.nv_sg_vpc2.id]


  user_data = <<-EOF
        #!/bin/bash
        yum install -y mysql56-server
       EOF
  
}

# Create VPC peering connection from VPC 1 to VPC 2

resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_vpc_id = aws_vpc.nv_vpc2.id
  vpc_id      = aws_vpc.nv_vpc1.id
  auto_accept = true
}

# Accept VPC peering connection in VPC 2
resource "aws_vpc_peering_connection_accepter" "accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  auto_accept               = true
}

# Create route from VPC 1 private subnet to VPC 2
 resource "aws_route" "route_to_vpc2" {
   route_table_id         = aws_route_table.route_table_vpc1_private.id
   destination_cidr_block = aws_vpc.nv_vpc2.cidr_block
   vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Create route from VPC 2 private subnet to VPC 1

 resource "aws_route" "route_to_vpc1" {
   route_table_id         = aws_route_table.route_table_vpc2_private.id
  destination_cidr_block = aws_vpc.nv_vpc1.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}








