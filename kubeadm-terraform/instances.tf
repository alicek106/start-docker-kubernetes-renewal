# Random token for kubeadm bootstrap
resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}

locals {
  token = "${random_string.token_id.result}.${random_string.token_secret.result}"
  
  master_userdata = var.initialize_kubeadm ? templatefile("scripts/master.sh", {
    kubernetes_version = var.kubernetes_version
    master_config = templatefile("scripts/master.yaml", {
      token       = local.token
      pod_subnet  = var.pod_subnet
    })
  }) : ""
  
  worker_userdata = var.initialize_kubeadm ? templatefile("scripts/worker.sh", {
    kubernetes_version = var.kubernetes_version
    apiserver_ip       = aws_instance.master.private_ip
    worker_config = templatefile("scripts/worker.yaml", {
      token        = local.token
      apiserver_ip = aws_instance.master.private_ip
    })
  }) : ""
}

# Worker node setting
resource "aws_instance" "worker" {
  count                       = var.number_of_worker
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  iam_instance_profile        = aws_iam_instance_profile.worker.id
  subnet_id                   = aws_subnet.kubeadm_subnet.id
  private_ip                  = cidrhost(var.vpc_cidr, 30 + count.index)
  associate_public_ip_address = true
  source_dest_check           = false
  availability_zone           = var.zone
  vpc_security_group_ids      = [aws_security_group.kubeadm_sg.id]
  key_name                    = var.default_keypair_name

  tags = merge(
    local.common_tags,
    {
      Name = "kubeadm_worker${count.index}"
    }
  )
  
  user_data = local.worker_userdata
  
  depends_on = [aws_instance.master]
}

# Master node setting
resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.master_instance_type
  iam_instance_profile        = aws_iam_instance_profile.master.id
  subnet_id                   = aws_subnet.kubeadm_subnet.id
  private_ip                  = cidrhost(var.vpc_cidr, 10)
  associate_public_ip_address = true
  source_dest_check           = false
  availability_zone           = var.zone
  vpc_security_group_ids      = [aws_security_group.kubeadm_sg.id]
  key_name                    = var.default_keypair_name

  tags = merge(
    local.common_tags,
    {
      Name = "kubeadm_master"
    }
  )
  
  user_data = local.master_userdata
}