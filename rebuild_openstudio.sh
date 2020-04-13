#!/bin/bash -e

#docker image rm docker-openstudio -f
docker build . -t="docker-openstudio:$1$2" --build-arg OPENSTUDIO_VERSION=$1 --build-arg OPENSTUDIO_VERSION_EXT=$2 --build-arg OPENSTUDIO_SHA=$3