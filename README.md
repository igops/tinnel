
$ docker run \
  --rm \
  --name=tinnel-bastion \
  -p 2022:22 \
  tinnel:latest \
  --mode=bastion

$ docker run \
  --rm \
  --name=tinnel-forward \
  -it \
  -p 9000:9000 \
  tinnel:latest \
  --mode=forward \
  --ssh-host=host.docker.internal \
  --ssh-port=2022 \
  --target-host=host.docker.internal \
  --target-port=8080 \
  --generate-keys

$ docker run \
  --rm\
  --name=tinnel-reverse \
  -it \
  tinnel:latest \
  --mode=reverse \
  --ssh-host=host.docker.internal \
  --ssh-port=2022 \
  --source-port=9000 \
  --target-host=host.docker.internal \
  --target-port=8080 \
  --generate-keys
