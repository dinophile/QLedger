{
  {
    "command": [

    ],
    "entryPoint": [],
    "environment": [],
    "essential": true,
    "image": "${account}.dkr.ecr.${region}.amazonaws.com/qledger:${tag}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "option": {
        "awslogs-group": "/$env/qledger",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "qledger-KOHO"
      }
    },
    "name": "qledger-KOHO",
    "portMappings" : [
      {
        "containerPort": ${app_port},
        "hostPort": ${host_port},
        "protocol": "tcp"
      }
    ]
  }
}