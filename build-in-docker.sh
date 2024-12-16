#!/bin/bash

docker run --platform linux/arm64 \
    --privileged --rm \
    -v $(pwd):/mnt debian:bookworm bash \
    -c "INSTALL_DEPS=true /mnt/build-os.sh /mnt/data /mnt/archive.swu"
