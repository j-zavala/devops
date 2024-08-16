# Single ECR Repository for both Frontend and API
resource "aws_ecr_repository" "app_ecr" {
  name                 = "${var.app_name}-ecr"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.app_name}-ecr"
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "app_ecr_lifecycle_policy" {
  repository = aws_ecr_repository.app_ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 frontend images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["frontend-"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 backend images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["backend-"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
