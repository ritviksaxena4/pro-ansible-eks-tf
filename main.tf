# # Security Group for Ansible Server 
# resource "aws_security_group" "ansible_sg" {
#   name        = "ansible-sg"
#   description = "Allow controlled access to Ansible"
#   vpc_id      = "vpc-0556f825c5ed6362b"

#   ingress {
#     description = "SSH from trusted IPs"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] 
#   }
#   ingress {
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # Security Group Rules for Ansible-EKS Communication
# resource "aws_security_group_rule" "ansible_to_eks" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.ansible_sg.id
#   source_security_group_id = aws_security_group.eks_nodes_sg.id
# }

# resource "aws_security_group_rule" "eks_to_ansible" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.eks_nodes_sg.id
#   source_security_group_id = aws_security_group.ansible_sg.id
# }

# # Ansible Server Instance 
# resource "aws_instance" "ansible_server" {
#   ami                    = "ami-04b4f1a9cf54c11d0"
#   instance_type          = "t2.large"
#   key_name               = "terraformkp1"
#   vpc_security_group_ids = [aws_security_group.ansible_sg.id]

#   user_data = <<-EOF
#     #!/bin/bash
#     sudo apt update -y
#     sudo apt install -y python3
#     sudo apt install openjdk-21-jdk -y
#     sudo apt install -y ansible
#     # Clone the Ansible project from GitHub

#     git clone https://github.com/ritviksaxena4/ansible-playbooks.git /home/ubuntu/ansible-project

#     sleep 5

#     chown -R ubuntu:ubuntu /home/ubuntu/ansible-project

#     cd ansible-project

#     #DONT NEED TO RUN AS OF NOW,, CREATE A PIPELINE FOR RUNNING THE CMDS
#     #ansible-playbook -i inventory playbook.yaml
# EOF
#   tags = {
#     Name = "Ansible-Server"
#   }
# }




##############################################################################################################

######## ANSIBLE SERVER CONFIG ########

##############################################################################################################
# Security Group for Ansible Server
resource "aws_security_group" "ansible_sg" {
  name        = "ansible-sg"
  description = "Allow controlled access to Ansible"
  vpc_id      = "vpc-0556f825c5ed6362b"

  ingress {
    description = "SSH from trusted IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with trusted IPs for better security
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role for Ansible Server
resource "aws_iam_role" "ansible_role" {
  name               = "ansible-server-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach Required Policies to IAM Role
resource "aws_iam_role_policy_attachment" "ansible_eks_cluster_policy" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "ansible_ecr_policy" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ansible_ssm_policy" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ansible_ec2_readonly_policy" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ansible_s3_readonly_policy" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# IAM Instance Profile for Ansible Server Role
resource "aws_iam_instance_profile" "ansible_instance_profile" {
  name = aws_iam_role.ansible_role.name
  
  role       = aws_iam_role.ansible_role.name
}

# Ansible Server Instance with IAM Role Attached
resource "aws_instance" "ansible_server" {
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.large"
  key_name               = "terraformkp1"
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  
  iam_instance_profile   = aws_iam_instance_profile.ansible_instance_profile.name

  user_data              = <<-EOF
#!/bin/bash

sudo apt update -y
sudo apt install -y python3
sudo apt install openjdk-21-jdk -y
sudo apt install -y ansible


# Update system and install required packages
sudo apt update -y && sudo apt install -y python3 python3-pip git ansible openjdk-21-jdk

# Install AWS SDK for Python (boto3)
pip3 install boto3 botocore

ansible-galaxy collection install amazon.aws


# Clone the Ansible project from GitHub
git clone https://github.com/ritviksaxena4/ansible-playbooks.git /home/ubuntu/ansible-project

sleep 5

chown -R ubuntu:ubuntu /home/ubuntu/ansible-project

cd /home/ubuntu/ansible-project

# run this on the jenkisn pipeline
#ansible-playbook -i inventory/aws_ec2.yml playbook.yaml

EOF

tags = {
    Name = "Ansible-Server"
}
}


##############################################################################################################

######## EKS CLUSTER CONFIG ########

##############################################################################################################
# ---------------------------
# EKS Components
# ---------------------------

# Dedicated EKS Cluster Security Group
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "EKS control plane communication"
  vpc_id      = "vpc-0556f825c5ed6362b"
}

# Updated EKS Worker Nodes Security Group
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "EKS worker node communication"
  vpc_id      = "vpc-0556f825c5ed6362b"

  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Roles and Policies 
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.31"

  vpc_config {
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    subnet_ids         = ["subnet-069745ef2b6c70f08", "subnet-000d8c38785a81b4f"]
  }
}

# Node IAM Role
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Node Group
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = ["subnet-069745ef2b6c70f08", "subnet-000d8c38785a81b4f"]
  ami_type        = "AL2_x86_64"
  instance_types  = ["t3.medium"]
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  remote_access {
    ec2_ssh_key = "terraformkp1"
  }
  tags = {
    Name = "worker-nodes"
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry
  ]


}


