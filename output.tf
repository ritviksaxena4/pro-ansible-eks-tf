output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "ansible_server_ip" {
  value = aws_instance.ansible_server.public_ip
}
