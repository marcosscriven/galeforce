#! /bin/bash

echo "Patching..."

scriptDir=$(dirname "$0")
rootDir="$scriptDir/../"
cp -R $scriptDir/root/* $rootDir