#!/usr/bin/env bash
VERSION=`git describe --tags`

cat << EOF
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "djrut/trinity:$VERSION",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "80"
    }
  ],
  "Logging": "/var/log/"
}
EOF
