#!/usr/bin/env bash

mkdir -p test_samples

# Make sure images are up-to-date:
docker pull stratumn/go-chainscript:latest
docker pull stratumn/js-chainscript:latest

# Generate test samples from all repositories:
docker run --mount type=bind,source="$(pwd)"/test_samples,target=/samples stratumn/go-chainscript:latest generate /samples/go-samples.json
if [ ! $? -eq 0 ]; then
    exit 1
fi

docker run --mount type=bind,source="$(pwd)"/test_samples,target=/samples stratumn/js-chainscript:latest generate /samples/js-samples.json
if [ ! $? -eq 0 ]; then
    exit 1
fi

# Verify files:
if [ ! -e ./test_samples/go-samples.json ]; then
    echo "go-samples.json is missing"
    exit 1
fi

if [ ! -e ./test_samples/js-samples.json ]; then
    echo "js-samples.json is missing"
    exit 1
fi

# Validate test samples:
echo "---------- Javascript ----------"
docker run --mount type=bind,source="$(pwd)"/test_samples,target=/samples stratumn/js-chainscript:latest validate /samples/go-samples.json
if [ ! $? -eq 0 ]; then
    exit 1
fi
echo "--------------------"

echo "---------- Golang ----------"
docker run --mount type=bind,source="$(pwd)"/test_samples,target=/samples stratumn/go-chainscript:latest validate /samples/js-samples.json
if [ ! $? -eq 0 ]; then
    exit 1
fi
echo "--------------------"
