#!/bin/bash

username=$(oc config view -o json | jq '."current-context"' -r | cut -d "/" -f 3)
domain=$(oc config view -o json | jq '."current-context"' -r | cut -d "/" -f 2)
namespace=$(oc config view -o json | jq '."current-context"' -r | cut -d "/" -f 1)
token=$(oc config view -o json --raw | jq '.users[] | select(.name | contains("'$domain'")) | .user.token' -r)

echo skopeo login -u $username -p TOKEN docker-registry.rahti.csc.fi
skopeo login -u $username -p $token docker-registry.rahti.csc.fi

echo skopeo copy docker://docker-registry.rahti.csc.fi/chipster-images-release/ubuntu:20.04 docker://docker-registry.rahti.csc.fi/$namespace/ubuntu:20.04
skopeo copy docker://docker-registry.rahti.csc.fi/chipster-images-release/ubuntu:20.04 docker://docker-registry.rahti.csc.fi/$namespace/ubuntu:20.04
echo skopeo copy docker://docker-registry.rahti.csc.fi/chipster-images-release/ubuntu:16.04 docker://docker-registry.rahti.csc.fi/$namespace/ubuntu:16.04
skopeo copy docker://docker-registry.rahti.csc.fi/chipster-images-release/ubuntu:16.04 docker://docker-registry.rahti.csc.fi/$namespace/ubuntu:16.04