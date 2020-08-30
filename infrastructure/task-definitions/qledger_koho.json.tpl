{
  {
    "command": [

    ],
    "entryPoint": [],
    "environment": [],
    "essential": true,
    "image": "${aws_ecr_repository.qledger_koho.repository_url}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "option": {
        "awslogs-group": "/$env/qledger",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "qledger_koho"
      }
    },
    "name": "qledger_koho",
    "portMappings" : [
      {
        "containerPort": ${app_port},
        "hostPort": ${host_port},
        "protocol": "tcp"
      }
    ]
  }
}