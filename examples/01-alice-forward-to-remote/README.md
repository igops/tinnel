*In this example, Alice will access a private (not available over internet) web service running on a server with public IP assigned*

### 1. Set up the bastion host
1.1. Spin up a tiny Linux virtual machine with a public IP assigned. E.g., you can run it in free tier of Google Cloud.

1.2. Install Docker and according to the official documentation.

1.3. Run some web service on the bastion host machine without exposing it to the outside, e.g. you can run nginx as a docker container without publishing any ports:
```shell 
$ docker run --rm --name=nginx nginx:alpine
```

> ⚠️  Double check this web service is not accessible by the public IP address of the bastion host; otherwise the further setup doesn't make any sense.

1.4. Run tinnel in bastion mode with port 2022 forwarded to 22. Alice will use this port to forward her TCP/IP packets over the SSH tunnel:
```shell
$ docker run \
  --rm \
  --name=tinnel-bastion \
  -p 2022:22 \
  igops/tinnel:latest \
  --mode=bastion
```

You should see something like this:
```
 🎩 I'm running in bastion mode
 ...
 Waiting for SSH connections...
```

1.5. Create a docker network to allow both containers to communicate with each other:
```shell
$ docker network create tinnel \
&& docker network connect tinnel tinnel-bastion \
&& docker network connect tinnel nginx
```

Now, you should be able to access nginx endpoints from the tinnel-bastion container just by using `nginx` (the name of the container) as hostname:
```shell
$ docker exec tinnel-bastion sh -c "apk add --no-cache curl && curl -s http://nginx"
```
Would print out the default nginx page:
```
...
<!DOCTYPE html>
...
<h1>Welcome to nginx!</h1>
...
```

Please note, the nginx container is still not accessible from the outside, only from the tinnel-bastion container.

### 2. Set up Alice's machine

2.1. Run tinnel in forward mode with `--generate-keys` flag with port 8080 forwarded to 9000. This port will be used by Alice to forward TCP/IP packets to the bastion host over the SSH tunnel. Please note we specify `nginx:80` as the target host and port, as it is the effective endpoint to reach the web service (see step `1.5` above). Also, since this container requires keyboard interaction, it should be run in interactive tty mode (`-it`):

On Mac OS X and Linux:
```shell
$ docker run \
  --rm \
  --name=tinnel-forward \
  -it \
  -p 8080:9000 \
  igops/tinnel:latest \
  --mode=forward \
  --ssh-host=<bastion-ip-address> \
  --ssh-port=2022 \
  --source-port=9000 \
  --target-host=nginx \
  --target-port=80 \
  --generate-keys
```

On Windows (PowerShell):
```
docker run `
  --rm `
  --name=tinnel-forward `
  -it `
  -p 8080:9000 `
  igops/tinnel:latest `
  --mode=forward `
  --ssh-host=<bastion-ip-address> `
  --ssh-port=2022 `
  --source-port=9000 `
  --target-host=nginx `
  --target-port=80 `
  --generate-keys
```

2.4. A new key pair will be generated automatically, and you will be prompted to copy the public key to the bastion.

Ensure you have the following success message at the end of the container logs:
``` 
Authenticated to <bastion-host-ip> using "publickey".
```

### 3. Try it out!
Alice should be able to access the private remote web service by visiting `http://localhost:8080` in her web browser locally.
 
