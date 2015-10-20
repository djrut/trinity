#!/usr/bin/env bash
USER="djrut"
REPO="trinity"
VERSION=$(git describe --tags)

cat << EOF
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "$USER/$REPO:$VERSION",
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
