#!/bin/bash

# build and run script for np-repro

PRIVILEGE_OPTS="--privileged --cap-add=SYS_PTRACE --security-opt seccomp=unconfined"

# if $1 is not empty, then enable privilege mode
if [ -n "$1" ]; then
    OPTS=${PRIVILEGE_OPTS}
fi


echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
docker rm -f np-repro
docker build -t np-repro .
docker run --name np-repro --rm -it ${OPTS} np-repro
