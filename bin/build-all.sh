#! /bin/bash

echo "Building all artifacts."
$(dirname "$0")/build-galeforce.sh
if [ $? -eq 0 ]; then
    $(dirname "$0")/build-image.sh
fi