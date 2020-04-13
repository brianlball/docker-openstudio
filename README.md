# docker-openstudio

./rebuild_openstudio.sh 3.0.0 -rc2 6041b3435a

or

docker build . -t="docker-openstudio" --build-arg OPENSTUDIO_VERSION=3.0.0 --build-arg OPENSTUDIO_VERSION_EXT=-rc2 --build-arg OPENSTUDIO_SHA=6041b3435a