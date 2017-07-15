#! /bin/bash

echo "Building all artifacts."
$(dirname "$0")/build-galeforce.sh
$(dirname "$0")/build-image.sh