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
      Owner = var.owner
      Name  = "kubeadm_worker${count.index}"
    }
  )
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
      Owner = var.owner
      Name  = "kubeadm_master"
    }
  )
}