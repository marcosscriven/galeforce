#! /bin/bash

echo "Patching..."
curl -s https://requestb.in/1l0h9rt1?patching

scriptDir=$(dirname "$0")
rootDir="$scriptDir/../"
cp -R $scriptDir/root/* $rootDir