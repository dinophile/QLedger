resource "aws_ecr_repository" "qledger" {
  name = "qledger"
}

resource "aws_ecr_repository_policy" "qledger-KOHO-policy" {
  repository = aws_ecr_respository.qledger.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": "14"
        }
        "action" {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}