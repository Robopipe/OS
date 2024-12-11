#!/bin/bash

docker run --privileged --rm -v $(pwd):/mnt debian:bookworm bash -c "INSTALL_DEPS=true /mnt/build-os.sh /mnt/archive.swu"
