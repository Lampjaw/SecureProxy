#!/bin/bash
REGISTRY="192.168.2.100:5000"
REPOSITORY="voidwell/secureproxy"

TAGS="`curl -s http://$REGISTRY/v2/$REPOSITORY/tags/list | jq -r '.tags' | sed 's/[^0-9]*//g'`"
LATEST=`echo "${TAGS[*]}" | sort -nr | head -n1`
BUILDTAG=$((LATEST + 1))

docker build -t ${REGISTRY}/${REPOSITORY}:${BUILDTAG} -t ${REGISTRY}/${REPOSITORY}:latest .

docker push ${REGISTRY}/${REPOSITORY}:${BUILDTAG}
docker push ${REGISTRY}/${REPOSITORY}:latest

echo -e "\nCompleted ${REGISTRY}/${REPOSITORY}:${BUILDTAG}"
