*In this example, Alice will make an arbitrary local web service available over the Internet*

### 1. Set up the bastion host
1.1. Spin up a tiny Linux virtual machine with a public IP assigned. E.g., you can run it in free tier of Google Cloud.

1.2. Install Docker and according to the official documentation.

1.3. Run tinnel in bastion mode with port 2022 forwarded to 22 to listen for SSH connections, and port 80 forwarded to 9000. The latter will be used to route the incoming TCP/IP packets back to Alice: 
```shell
$ docker run \
  --rm \
  --name=tinnel-bastion \
  -p 2022:22 \
  -p 80:9000 \
  igops/tinnel:latest \
  --mode=bastion
```

You should see something like this:
```
 🎩 I'm running in bastion mode
 ...
 Waiting for SSH connections...
```

### 2. Set up Alice's machine
2.2. Run some web service locally, e.g. you can run nginx on port 8080:
```shell 
$ docker run --rm -p 8080:80 nginx:alpine
``` 

2.3. Run tinnel in reverse mode with `--generate-keys` flag:

On Mac OS X:
```shell
$ docker run \
  --rm \
  --name=tinnel-reverse \
  -it \
  igops/tinnel:latest \
  --mode=reverse \
  --ssh-host=<bastion-ip-address> \
  --ssh-port=2022 \
  --source-port=9000 \
  --target-host=host.docker.internal \
  --target-port=8080 \
  --generate-keys
```

On Linux:
```
$ docker run \
  --rm \
  --name=tinnel-reverse \
  -it \
  --add-host="host.docker.internal:host-gateway" \
  igops/tinnel:latest \
  --mode=reverse \
  --ssh-host=<bastion-ip-address> \
  --ssh-port=2022 \
  --source-port=9000 \
  --target-host=host.docker.internal \
  --target-port=8080 \
  --generate-keys
```

On Windows (PowerShell):
```
docker run `
  --rm `
  --name=tinnel-reverse `
  -it `
  igops/tinnel:latest `
  --mode=reverse `
  --ssh-host=<bastion-ip-address> `
  --ssh-port=2022 `
  --source-port=9000 `
  --target-host=host.docker.internal `
  --target-port=8080 `
  --generate-keys
```

2.4. A new key pair will be generated automatically, and you will be prompted to copy the public key to the bastion.

Ensure you have the following success message at the end of the container logs:
``` 
Authenticated to <bastion-host-ip> using "publickey".
```

### 3. Try it out!
Access Alice's local web service by visiting `http://bastion-ip-address` in your web browser.
 
