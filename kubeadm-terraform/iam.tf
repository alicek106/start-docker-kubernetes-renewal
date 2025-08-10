# IAM Role for Kubernetes Master
resource "aws_iam_role" "master" {
  name = "master_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "master_role"
      Type = "kubernetes-master"
    }
  )
}

# IAM Policy for Kubernetes Master
resource "aws_iam_role_policy" "master" {
  name = "master_policy"
  role = aws_iam_role.master.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "route53:*",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile for Master
resource "aws_iam_instance_profile" "master" {
  name = "master_instance_profile"
  role = aws_iam_role.master.name

  tags = merge(
    local.common_tags,
    {
      Name = "master_instance_profile"
    }
  )
}

# IAM Role for Kubernetes Worker
resource "aws_iam_role" "worker" {
  name = "worker_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "worker_role"
      Type = "kubernetes-worker"
    }
  )
}

# IAM Policy for Kubernetes Worker
resource "aws_iam_role_policy" "worker" {
  name = "worker_policy"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile for Worker
resource "aws_iam_instance_profile" "worker" {
  name = "worker_instance_profile"
  role = aws_iam_role.worker.name

  tags = merge(
    local.common_tags,
    {
      Name = "worker_instance_profile"
    }
  )
}