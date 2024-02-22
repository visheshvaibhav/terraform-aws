provider "aws" {
  region = "us-east-1"
}


#create vpc
resource "aws_vpc" "dev" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "dev"
  }

}

#create gateweay

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "dev"
  }

}

#create route table

resource "aws_route_table" "rt-1" {
  vpc_id = aws_vpc.dev.id


  #ipv4
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  #ipv6
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "dev-1"
  }

}



#CREATE SUBNET

resource "aws_subnet" "dev-1-1a" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"


  tags = {
    Name = "dev-1-1a"
  }
}

resource "aws_subnet" "dev-1-1b" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"


  tags = {
    Name = "dev-1-1b"
  }
}

resource "aws_subnet" "dev-1-1c" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"


  tags = {
    Name = "dev-1-1c"
  }
}

resource "aws_subnet" "dev-1-1d" {
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1d"


  tags = {
    Name = "dev-1-1d"
  }
}

#Associate route table with subnet

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.dev-1-1a.id
  route_table_id = aws_route_table.rt-1.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.dev-1-1b.id
  route_table_id = aws_route_table.rt-1.id

}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.dev-1-1c.id
  route_table_id = aws_route_table.rt-1.id

}

resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.dev-1-1d.id
  route_table_id = aws_route_table.rt-1.id
}

#create security group to allow SSH, HTTP

resource "aws_security_group" "dev-1" {
  name        = "dev-1"
  description = "Allow http and SSH"
  vpc_id      = aws_vpc.dev.id

  ingress {
    description = "HTTP"
    to_port     = "80"
    from_port   = "80"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  ingress {
    description = "SSH"
    to_port     = "22"
    from_port   = "22"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }

  egress {
    to_port     = "0"
    from_port   = "0"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }

  tags = {
    Name = "dev-1"


  }
}

#crete security group for load balancer to allow http request

resource "aws_security_group" "dev-2" {
  name        = "dev-2"
  description = "Allow http"
  vpc_id      = aws_vpc.dev.id

  ingress {
    description = "HTTP"
    to_port     = "80"
    from_port   = "80"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  egress {
    to_port     = "0"
    from_port   = "0"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }

  tags = {
    Name = "dev-2"


  }
}

#Create Target group


resource "aws_lb_target_group" "tg-1" {
  name     = "tg-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.dev.id
}

#Create load balancer

resource "aws_lb" "dev" {
  name               = "dev"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dev-2.id]
  subnets            = [aws_subnet.dev-1-1a.id, aws_subnet.dev-1-1b.id, aws_subnet.dev-1-1c.id, aws_subnet.dev-1-1d.id]

}

resource "aws_lb_listener" "dev" {
  load_balancer_arn = aws_lb.dev.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-1.arn
  }

}

resource "aws_launch_template" "dev-1" {
  name          = "dev-1-1"
  image_id      = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  key_name      = "dev-1"
  network_interfaces {
    security_groups             = [aws_security_group.dev-1.id]
    associate_public_ip_address = true
  }

  user_data = base64encode(<<EOF
#! /bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2n
echo "Hello, World. Made by Vishesh Vaibhav for Cloud Programming - DLBSEPCP01_E" | sudo tee /var/www/html/index.html
EOF
  )
  tags = {
    Name = "dev-1"
  }
}

resource "aws_autoscaling_group" "dev-1" {
  name                      = "dev-1"
  vpc_zone_identifier       = [aws_subnet.dev-1-1a.id, aws_subnet.dev-1-1b.id, aws_subnet.dev-1-1c.id, aws_subnet.dev-1-1d.id]
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 2
  health_check_grace_period = 20
  health_check_type         = "ELB"
  launch_template {
    id      = aws_launch_template.dev-1.id
    version = "$Default"
  }


}

resource "aws_autoscaling_attachment" "dev-1" {
  autoscaling_group_name = aws_autoscaling_group.dev-1.id
  lb_target_group_arn    = aws_lb_target_group.tg-1.arn

}



# #CREATE NETWORK INTERFACE

# resource "aws_network_interface" "dev-1-1a" {
#   subnet_id       = aws_subnet.dev-1-1a.id
#   private_ips     = ["10.0.1.50"]
#   security_groups = [aws_security_group.dev-1.id]

# }

# resource "aws_network_interface" "dev-1-1b" {
#   subnet_id       = aws_subnet.dev-1-1b.id
#   private_ips     = ["10.0.2.50"]
#   security_groups = [aws_security_group.dev-1.id]

# }

# resource "aws_network_interface" "dev-1-1c" {
#   subnet_id       = aws_subnet.dev-1-1c.id
#   private_ips     = ["10.0.3.50"]
#   security_groups = [aws_security_group.dev-1.id]

# }

# resource "aws_network_interface" "dev-1-1d" {
#   subnet_id       = aws_subnet.dev-1-1d.id
#   private_ips     = ["10.0.4.50"]
#   security_groups = [aws_security_group.dev-1.id]

# }



# #assign elastic IP
# resource "aws_eip" "one" {
#   domain                    = "vpc"
#   network_interface         = aws_network_interface.dev-1-1a.id
#   associate_with_private_ip = "10.0.1.50"
#   depends_on                = [aws_internet_gateway.gw]
# }

# resource "aws_eip" "two" {
#   domain                    = "vpc"
#   network_interface         = aws_network_interface.dev-1-1b.id
#   associate_with_private_ip = "10.0.2.50"
#   depends_on                = [aws_internet_gateway.gw]
# }


# resource "aws_eip" "three" {
#   domain                    = "vpc"
#   network_interface         = aws_network_interface.dev-1-1c.id
#   associate_with_private_ip = "10.0.3.50"
#   depends_on                = [aws_internet_gateway.gw]
# }

# resource "aws_eip" "four" {
#   domain                    = "vpc"
#   network_interface         = aws_network_interface.dev-1-1d.id
#   associate_with_private_ip = "10.0.4.50"
#   depends_on                = [aws_internet_gateway.gw]
# }

# #create instance
# resource "aws_instance" "dev-1-1a" {
#   ami           = "ami-0c7217cdde317cfec"
#   instance_type = "t2.micro"
#   key_name      = "dev-1"


#   network_interface {
#     device_index         = 0
#     network_interface_id = aws_network_interface.dev-1-1a.id
#   }

#   user_data = <<-EOF
#             #!/bin/bash
#             sudo apt update -y
#             sudo apt install apache2 -y
#             sudo systemctl start apache2
#             sudo bash -c 'echo Hello, world. Made by Vishesh Vaibhav. For course - Cloud Programming(DLBSEPCP01_E) > /var/www/html/index.html'
#             EOF
#   tags = {
#     Name = "dev-1-1a"
#   }

# }

# resource "aws_instance" "dev-1-1b" {
#   ami           = "ami-0c7217cdde317cfec"
#   instance_type = "t2.micro"
#   key_name      = "dev-1"


#   network_interface {
#     device_index         = 0
#     network_interface_id = aws_network_interface.dev-1-1b.id
#   }
#   user_data = <<-EOF
#             #!/bin/bash
#             sudo apt update -y
#             sudo apt install apache2 -y
#             sudo systemctl start apache2
#             sudo bash -c 'echo Hello, world. Made by Vishesh Vaibhav. For course - Cloud Programming(DLBSEPCP01_E) > /var/www/html/index.html'
#             EOF

#   tags = {
#     Name = "dev-1-1b"
#   }

# }

# resource "aws_instance" "dev-1-1c" {
#   ami           = "ami-0c7217cdde317cfec"
#   instance_type = "t2.micro"
#   key_name      = "dev-1"


#   network_interface {
#     device_index         = 0
#     network_interface_id = aws_network_interface.dev-1-1c.id
#   }
#   user_data = <<-EOF
#             #!/bin/bash
#             sudo apt update -y
#             sudo apt install apache2 -y
#             sudo systemctl start apache2
#             sudo bash -c 'echo Hello, world. Made by Vishesh Vaibhav. For course - Cloud Programming(DLBSEPCP01_E) > /var/www/html/index.html'
#             EOF

#   tags = {
#     Name = "dev-1-1c"
#   }

# }
# resource "aws_instance" "dev-1-1d" {
#   ami           = "ami-0c7217cdde317cfec"
#   instance_type = "t2.micro"
#   key_name      = "dev-1"


#   network_interface {
#     device_index         = 0
#     network_interface_id = aws_network_interface.dev-1-1d.id
#   }
#   user_data = <<-EOF
#             #!/bin/bash
#             sudo apt update -y
#             sudo apt install apache2 -y
#             sudo systemctl start apache2
#             sudo bash -c 'echo Hello, world. Made by Vishesh Vaibhav. For course - Cloud Programming(DLBSEPCP01_E) > /var/www/html/index.html'
#             EOF
#   tags = {
#     Name = "dev-1-1d"
#   }

# }


# resource "aws_ami_from_instance" "dev-1-1a" {
#   name               = "dev-1-1a"
#   source_instance_id = aws_instance.dev-1-1a.id
# }




# resource "aws_autoscaling_group" "dev-1-1a" {
#   name                      = "dev-1-1a"
#   vpc_zone_identifier       = ["subnet-0eac765445e86c097"]
#   max_size                  = 10
#   min_size                  = 5
#   desired_capacity          = 7
#   health_check_grace_period = 60

#   launch_template {
#     id      = aws_launch_template.dev-1.id
#     version = "$Default"

#   }

# }


# resource "aws_autoscaling_group" "dev-1-1b" {
#   name                      = "dev-1-1b"
#   vpc_zone_identifier       = ["subnet-031d39488e1fe53e8"]
#   max_size                  = 10
#   min_size                  = 5
#   desired_capacity          = 7
#   health_check_grace_period = 60

#   launch_template {
#     id      = aws_launch_template.dev-1.id
#     version = "$Default"

#   }

# }

# resource "aws_autoscaling_group" "dev-1-1c" {
#   name                      = "dev-1-1c"
#   vpc_zone_identifier       = ["subnet-05b126ec96ee1443e"]
#   max_size                  = 10
#   min_size                  = 5
#   desired_capacity          = 7
#   health_check_grace_period = 60

#   launch_template {
#     id      = aws_launch_template.dev-1.id
#     version = "$Default"

#   }

# }

# resource "aws_autoscaling_group" "dev-1-1d" {
#   name                      = "dev-1-1d"
#   vpc_zone_identifier       = ["subnet-099290ac116741f10"]
#   max_size                  = 10
#   min_size                  = 5
#   desired_capacity          = 7
#   health_check_grace_period = 60

#   launch_template {
#     id      = aws_launch_template.dev-1.id
#     version = "$Default"

#   }

# }
