#!/bin/sh
#
# Build armv7l Ubuntu base images for docker (on x86 as well as armhf machines)
# - needs qemu-user-static installed
#
# The following distributions will be built:
# * 14.04, trusty
# * 13.10, saucy
# * 12.04, precise
#
# Synopsis: build-all.sh [IMAGE NAME]
#
# Defaults: build-all.sh <YOUR-DOCKER-USER>/armhf-ubuntu

# Fail on error
set -e

# Check if current user is member of docker group and only use sudo if necessary
DOCKER_CMD=docker
if ! id -Gn | grep -qw 'docker'; then
  DOCKER_CMD=sudo $DOCKER_CMD
fi

if [ -n "$1" ]; then
  IMAGE_NAME=$1
else
  DOCKER_USER=$($DOCKER_CMD info | grep Username | awk '{print $2;}')
  IMAGE_NAME=$DOCKER_USER/armhf-ubuntu
fi

echo Using $IMAGE_NAME as a base image name

./build.sh 15.10 $IMAGE_NAME
$DOCKER_CMD push $IMAGE_NAME:15.10
$DOCKER_CMD tag -f $IMAGE_NAME:15.10 $IMAGE_NAME:latest
$DOCKER_CMD push $IMAGE_NAME:latest
$DOCKER_CMD tag -f $IMAGE_NAME:15.10 $IMAGE_NAME:wily
$DOCKER_CMD push $IMAGE_NAME:wily

./build.sh 15.04
$DOCKER_CMD push $IMAGE_NAME:15.04
$DOCKER_CMD tag -f $IMAGE_NAME:15.04 $IMAGE_NAME:vivid
$DOCKER_CMD push $IMAGE_NAME:vivid

./build.sh 14.04.3
$DOCKER_CMD tag -f $IMAGE_NAME:14.04.3 $IMAGE_NAME:14.04
$DOCKER_CMD push $IMAGE_NAME:14.04.3
$DOCKER_CMD tag -f $IMAGE_NAME:14.04.3 $IMAGE_NAME:trusty
$DOCKER_CMD push $IMAGE_NAME:trusty

./build.sh 12.04.5
$DOCKER_CMD tag -f $IMAGE_NAME:12.04.5 $IMAGE_NAME:12.04
$DOCKER_CMD push $IMAGE_NAME:12.04.5
$DOCKER_CMD tag -f $IMAGE_NAME:12.04.5 $IMAGE_NAME:precise
$DOCKER_CMD push $IMAGE_NAME:precise

echo Successfully pushed all images to $IMAGE_NAME
