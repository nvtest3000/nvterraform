

#Terrafrom code to automate DMS testing

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}


# Create public subnet

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Create route table
resource "aws_route_table" "my_public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.my_public_route_table.id
}

# Create private subnet
resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-1b"
}


# Create security group for EC2 instance

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_ipv4" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



#key set up

resource "tls_private_key" "nvkey1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_file1" {
  filename = "my-public-key.pem"
  content  = tls_private_key.nvkey1.private_key_pem
}

resource "aws_key_pair" "nv_public_key1" {
  key_name   = "my-public-key"
  public_key = tls_private_key.nvkey1.public_key_openssh
}


# Create EC2 instance in public subnet

resource "aws_instance" "nv_instance1" {
  ami           = var.ami_ids
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.nv_public_key1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

tags = {
    Name = "ec2_jumpinstance"
  }

  provisioner "local-exec" {
   command = "chmod  400 ${local_file.private_key_file1.filename}"
  }
}

# Create DB  Private subnet group

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.private_subnet1.id,aws_subnet.private_subnet2.id]
}

# Create RI Private subnet group

resource "aws_dms_replication_subnet_group" "ri_subnet_group" {
  replication_subnet_group_id = "ri-subnet-group"
  replication_subnet_group_description = " replication subnet group"
  subnet_ids = [
    aws_subnet.private_subnet1.id,
    aws_subnet.private_subnet2.id
  ]
}



# Create RDS PostgreSQL instances in private subnet

resource "aws_db_instance" "rds_instance1" {
  engine             = "postgres"
  instance_class     = "db.t3.medium"
  allocated_storage  = 20
  storage_type       = "gp2"
  identifier         = "rds-instance1"
  engine_version       = "14.11"
  username           = "dmstest"
  password           = "password"
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
}

resource "aws_db_instance" "rds_instance2" {
  engine             = "postgres"
  instance_class     = "db.t3.medium"
  allocated_storage  = 20
  storage_type       = "gp2"
  identifier         = "rds-instance2"
  engine_version       = "14.11"
  username           = "dmstest"
  password           = "password"
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
}

# Create DMS replication instance

resource "aws_dms_replication_instance" "replication_instance" {
  replication_instance_class = "dms.t3.medium"
  allocated_storage           = 20
  engine_version              = "3.5.1"
  publicly_accessible         = false
  replication_instance_id      = "test-dms-replication-instance-tf"
  vpc_security_group_ids      = [aws_security_group.dms_sg.id]
  replication_subnet_group_id = aws_dms_replication_subnet_group.ri_subnet_group.replication_subnet_group_id
 

}

# Create security group for DMS

resource "aws_security_group" "dms_sg" {
  name        = "dms_sg"
  description = "Allow DMS traffic"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.rds_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create security group for RDS

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow RDS traffic"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configure source and target endpoints for DMS

resource "aws_dms_endpoint" "source_endpoint" {
  endpoint_type = "source"
  engine_name   = "postgres"
  database_name = "postgres"
  username      = "dmstest"
  password      = "password"
  endpoint_id   = "test-dms-endpoint-source"
  server_name   = aws_db_instance.rds_instance1.address
  port          = 5432

}

resource "aws_dms_endpoint" "target_endpoint" {
  endpoint_type = "target"
  engine_name   = "postgres"
  database_name = "postgres"
  username      = "dmstest"
  password      = "password"
  endpoint_id   = "test-dms-endpoint-target"
  server_name   = aws_db_instance.rds_instance2.address
  port          = 5432
  
}



# Create DMS replication task
resource "aws_dms_replication_task" "replication_task" {
  migration_type             = "full-load"
  source_endpoint_arn        = aws_dms_endpoint.source_endpoint.endpoint_arn
  target_endpoint_arn        = aws_dms_endpoint.target_endpoint.endpoint_arn
  replication_instance_arn   = aws_dms_replication_instance.replication_instance.replication_instance_arn
  replication_task_id        = "my-test-task"
  table_mappings             = <<EOF
{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "1",
      "object-locator": {
        "schema-name": "public",
        "table-name": "%"
      },
      "rule-action": "include"
    }
  ]
}
EOF
}




