# Global tag
locals {
  common_tags = {
    "kubernetes.io/cluster/${var.cluster_id_tag}" = var.cluster_id_value
  }
}

# You can adjust below variables
variable "default_keypair_name" {
  description = "AWS key pair name for SSH access"
  type        = string
  default     = "mysshkey"
}

variable "number_of_worker" {
  description = "The number of worker nodes"
  type        = number
  default     = 1
}

variable "cluster_id_tag" {
  description = "Cluster ID tag for kubeadm"
  type        = string
  default     = "alice"
}

variable "cluster_id_value" {
  description = "Cluster ID value, it can be shared or owned"
  type        = string
  default     = "owned"
}

variable "control_cidr" {
  description = "CIDR of security group"
  type        = string
  default     = "0.0.0.0/0"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "alicek106"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "zone" {
  description = "AWS availability zone"
  type        = string
  default     = "ap-northeast-2a"
}

# VPC Settings
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.40.0.0/16"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "kubeadm_vpc"
}

variable "subnet_name" {
  description = "Name of the Subnet"
  type        = string
  default     = "kubeadm_subnet"
}

# Instance Types
variable "master_instance_type" {
  description = "EC2 instance type for master node"
  type        = string
  default     = "t2.medium"
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t2.medium"
}

# AMI is now automatically selected using data source for Ubuntu 24.04 LTS
# See data.tf for AMI selection logic