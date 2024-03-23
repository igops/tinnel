#!/bin/bash

# Parsing the flags (--option=argument) https://stackoverflow.com/a/14203146/20085654
for i in "$@"; do
  case $i in
    -m=*|--mode=*)
      MODE="${i#*=}"
      shift
      ;;
    --generate-keys)
      GENERATE_KEYS=true
      shift
      ;;
    --ssh-host=*)
      SSH_HOST="${i#*=}"
      shift
      ;;
    --ssh-port=*)
      SSH_PORT="${i#*=}"
      shift
      ;;
    --source-host=*)
      SOURCE_PORT="${i#*=}"
      shift
      ;;
    --source-port=*)
      SOURCE_PORT="${i#*=}"
      shift
      ;;
    --target-host=*)
      TARGET_HOST="${i#*=}"
      shift
      ;;
    --target-port=*)
      TARGET_PORT="${i#*=}"
      shift
      ;;
    --bastion-container-name=*)
      BASTION_CONTAINER_NAME="${i#*=}"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

if [ -z "$MODE" ]; then
  MODE=forward
fi 

if [ -z "$BASTION_CONTAINER_NAME" ]; then
  BASTION_CONTAINER_NAME=tinnel-bastion
fi

if [ "$MODE" == "bastion" ]; then
  echo "═════════════════════════════════════════════════════════════════════════"
  echo "  🎩 I'm running in bastion mode"
  echo 
  echo "  Please make sure this container is running on the machine which"
  echo "  has a public IP assigned, so you can use it as a proxy between a"
  echo "  forwarder and a reverser. Don't forget allowing incoming TCP/IP"
  echo "  traffic from the clients supposed to connect here. Please populate"
  echo "  /root/.ssh/authorized_keys with the public keys of the clients to be"
  echo "  able connect to this bastion. It could be done whenever later,"
  echo "  without restarting the container. Good luck!"
  echo "═════════════════════════════════════════════════════════════════════════"

  if [ -n "$SSH_HOST" ]; then
    echo "⚠️  --ssh-host=$SSH_HOST is ignored in bastion mode. Use this setting in forward and reverse modes to address the host or IP of the machine where bastion container is running."
  fi

  if [ -n "$SSH_PORT" ]; then
    echo "⚠️  --ssh-port=$SSH_PORT is ignored in bastion mode. Use this setting in forward and reverse modes to address the port on which bastion container is listening."
  fi

  if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
  fi

  if [ ! -d /root/.ssh ]; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
  fi

  echo "Waiting for SSH connections..."
  /usr/sbin/sshd -D
  exit 0
fi
 

if [ "$MODE" != "forward" ] && [ "$MODE" != "reverse" ]; then
  echo "❌ Unsupported --mode. Please specify one of the following:"
  echo "--mode=bastion to start in bastion mode"
  echo "--mode=forward to start in forward mode"
  echo "--mode=reverse to start in reverse mode"
  exit 1
fi

if [ -z "$SSH_HOST" ]; then
  echo "❌ --ssh-host is not set. Running in $MODE mode requires a bastion host with an IP assigned. Please specify it using --ssh-host=domain-name or --ssh-host=IP-address"
  exit 1
fi

if [ -z "$SSH_PORT" ]; then
  SSH_PORT=22
fi

if [ -z "$GENERATE_KEYS" ]; then
  GENERATE_KEYS=false
fi

if [ "$GENERATE_KEYS" == "true" ]; then
  ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -q -C "$MODE@tinnel" -P ""
fi

if [ "$MODE" == "forward" ]; then
  if [ -z "$SOURCE_PORT" ]; then
    SOURCE_PORT=9000
  fi

  if [ -z "$TARGET_HOST" ]; then
    TARGET_HOST="localhost"
  fi

  if [ -z "$TARGET_PORT" ]; then
    TARGET_PORT=9000
  fi

  echo "═════════════════════════════════════════════════════════════════════════"
  echo "  ⏩ I'm running in forward mode"
  echo
  echo "  I will open an SSH tunnel to $SSH_HOST:$SSH_PORT with -L option."
  echo "  Whenever you send a TCP/IP packet to this container on port $SOURCE_PORT,"
  echo "  I will forward it to the bastion container on $TARGET_HOST:$TARGET_PORT."
  echo
  echo "  🤠 Please add my key to the bastion container as follows:"
  echo
  echo "$ docker exec -it $BASTION_CONTAINER_NAME sh -c \"echo '$(cat /root/.ssh/id_ed25519.pub)' >> /root/.ssh/authorized_keys\""
  echo
  echo "═════════════════════════════════════════════════════════════════════════"
  read -p "Press ENTER to continue..."

  ssh -NT \
    -4 \
    -o StrictHostKeyChecking=no \
    -o ExitOnForwardFailure=yes \
    -o PreferredAuthentications=publickey \
    -o ServerAliveInterval=60 \
    -o LogLevel=VERBOSE \
    -l root \
    $SSH_HOST -p $SSH_PORT \
    -L 0.0.0.0:$SOURCE_PORT:$TARGET_HOST:$TARGET_PORT
  exit 0
fi

if [ "$MODE" == "reverse" ]; then
  if [ -z "$SSHD_PORT" ]; then
    SSHD_PORT=22
  fi

  if [ -z "$SOURCE_PORT" ]; then
    SOURCE_PORT=9000
  fi

  if [ -z "$TARGET_HOST" ]; then
    TARGET_HOST="host.docker.internal"
  fi

  if [ -z "$TARGET_PORT" ]; then
    TARGET_PORT=8080
  fi

  echo "═════════════════════════════════════════════════════════════════════════"
  echo "  ⚠️  DISCLAIMER"
  echo "  IF SOMEONE YOU DON'T TRUST TOLD YOU TO RUN THE COMMAND ABOVE, EXIT"
  echo "  IMMEDIATELY BY PRESSING CTRL+C! THIS PROGRAM CAN MAKE YOUR COMPUTER"
  echo "  VULNERABLE TO ATTACKS IF USED IMPROPERLY. PLEASE BE CAREFUL!"
  echo
  echo "  ⏪ Running in reverse mode"
  echo
  echo "  I will open an SSH tunnel to $SSH_HOST:$SSH_PORT with -R option."
  echo "  Whenever a TCP/IP packet is sent to the bastion container on port $SOURCE_PORT,"
  echo "  I will intercept it and forward to $TARGET_HOST:$TARGET_PORT."
  echo
  echo "  🤠 Please add my key to the bastion container as follows:"
  echo
  echo "$ docker exec -it $BASTION_CONTAINER_NAME sh -c \"echo '$(cat /root/.ssh/id_ed25519.pub)' >> /root/.ssh/authorized_keys\""
  echo
  echo "═════════════════════════════════════════════════════════════════════════"
  read -p "Press ENTER to continue..."

  ssh -NT \
    -4 \
    -o StrictHostKeyChecking=no \
    -o ExitOnForwardFailure=yes \
    -o PreferredAuthentications=publickey \
    -o ServerAliveInterval=60 \
    -o LogLevel=VERBOSE \
    -l root \
    $SSH_HOST -p $SSH_PORT \
    -R 0.0.0.0:$SOURCE_PORT:$TARGET_HOST:$TARGET_PORT
  exit 0
fi
