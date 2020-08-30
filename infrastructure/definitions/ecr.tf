resource "aws_ecr_repository" "qledger_koho" {
  name = "qledger_koho"
}

resource "aws_ecr_lifecycle_policy" "qledger_koho_policy" {
  repository = aws_ecr_repository.qledger_koho.name

  policy = <<EOF
{
    'rules': [{
        'rulePriority': 1,
        'selection': {
          'tagStatus': 'untagged',
          'countType': 'sinceImagePushed',
          'countUnit': 'days',
          'countNumber': '14'
        }
        'action' {
          'type': 'expire'
        }
      },
      {
        'rulePriority': 2,
        'description': 'Keep last 2 images',
        'selection': {
          'tagStatus': 'any',
          'countType': 'imageCountMoreThan',
          'countNumber': 2
        },
        'action': {
          'type': 'expire'
        }
    }
  ]
}
EOF
}
