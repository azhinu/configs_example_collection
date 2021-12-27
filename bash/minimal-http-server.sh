#!/usr/bin/env bash
# Simple HTTP server with NetCat. Return date.

# Default vars
listen=localhost
port=8080

# Parse Args
position=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -p|--port)
      port="$2"
      shift # past argument
      shift # past value
      ;;
    -l|--listen)
      listen="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      echo -e "Simple HTTP server \n -p  --port \t | Default 8080\n -l \t --listen \t | Default localhost"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      position+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

echo "Starting HTTP server on $listen:$port"
if [ "$(uname)" == "Darwin" ]; then
  while true; do echo -e "HTTP/1.1 200 OK\n\n $(date)" | nc -l $listen $port; done
else
  while true ; do nc -l $listen -p $port -c 'echo -e "HTTP/1.1 200 OK\n\n $(date)"'; done
fi
