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

if [ -n "$1" ]; then
  IMAGE_NAME=$1
else
  DOCKER_USER=$(sudo docker info | grep Username | awk '{print $2;}')
  IMAGE_NAME=$DOCKER_USER/armhf-ubuntu
fi

echo Using $IMAGE_NAME as a base image name

./build.sh 15.10 $IMAGE_NAME
sudo docker push $IMAGE_NAME:15.10
sudo docker tag -f $IMAGE_NAME:15.10 $IMAGE_NAME:latest
sudo docker push $IMAGE_NAME:latest
sudo docker tag -f $IMAGE_NAME:15.10 $IMAGE_NAME:wily
sudo docker push $IMAGE_NAME:wily

./build.sh 15.04
sudo docker push $IMAGE_NAME:15.04
sudo docker tag -f $IMAGE_NAME:15.04 $IMAGE_NAME:vivid
sudo docker push $IMAGE_NAME:vivid

./build.sh 14.04.3
sudo docker push $IMAGE_NAME:14.04.3
sudo docker tag -f $IMAGE_NAME:14.04.3 $IMAGE_NAME:14.04
sudo docker push $IMAGE_NAME:trusty
sudo docker tag -f $IMAGE_NAME:14.04.3 $IMAGE_NAME:trusty

./build.sh 12.04.5
sudo docker push $IMAGE_NAME:12.04.5
sudo docker tag -f $IMAGE_NAME:12.04.5 $IMAGE_NAME:12.04
sudo docker push $IMAGE_NAME:precise
sudo docker tag -f $IMAGE_NAME:12.04.5 $IMAGE_NAME:precise

echo Successfully pushed all images to $IMAGE_NAME
