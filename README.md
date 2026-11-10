# Robopipe OS: Linux operating system image for Robopipe machine vision controllers

**Robopipe OS is the operating system for Robopipe controllers, the industrial edge computers (AI PLCs) that run AI visual quality inspection on production lines. This repository contains the build scripts and the ready-to-install OS images.**

Robopipe OS is part of [Robopipe](https://robopipe.io/en), an industrial machine vision platform for AI quality control in manufacturing. The image is based on the Unipi Patron base OS (Debian) and comes with [Robopipe API](https://github.com/Robopipe/API) preinstalled. After installation, the controller connects Luxonis OAK cameras to the PLC inputs and outputs and runs AI inference at the edge.

## Features

- **Robopipe API preinstalled.** The build installs the latest [Robopipe API release](https://github.com/Robopipe/API/releases/latest) as a system service, with nginx in front of it.
- **Ready for the network.** Each controller gets the hostname `robopipe-<id>.local` and announces itself through mDNS (Avahi).
- **PLC inputs and outputs.** The image contains the Unipi hardware definitions, so Robopipe API can control digital, analog and relay inputs and outputs.
- **1-Wire support.** The image contains owserver for 1-Wire sensors.
- **Software update in the browser.** Install a new OS version through the service mode web page of the controller.
- **Reproducible builds.** Build the image yourself in Docker. GitHub Actions publishes each tagged version as a release.

## How Robopipe OS fits into Robopipe

| Part | What it does | Where it runs |
| --- | --- | --- |
| **[Robopipe Studio](https://github.com/Robopipe/Studio)** | Capture, labelling, training and deployment of AI models | Server or cloud, used in a web browser |
| **[Robopipe API](https://github.com/Robopipe/API)** | REST and WebSocket API for cameras, AI inference and PLC inputs and outputs | Robopipe controller or any Unix-based computer |
| **[Robopipe OS](https://github.com/Robopipe/OS)** (this repository) | Operating system image with Robopipe API preinstalled | Robopipe controller (based on Unipi Patron) |
| **[Luxonis OAK cameras](https://www.luxonis.com/)** | Image capture and on-device neural network inference | Above the production line |

## Install Robopipe OS on a controller

Read the [Robopipe documentation](https://robopipe.gitbook.io/doc) for a detailed guide.

1. Start the controller in service mode:
   1. Turn off the controller.
   2. Press and hold the _SERVICE_ button. It is usually next to the USB labels.
   3. Turn on the controller and continue to hold the _SERVICE_ button.
   4. Release the _SERVICE_ button when all LEDs blink periodically.
2. Download the **archive.swu** file from the [latest release of Robopipe OS](https://github.com/Robopipe/OS/releases/latest).
3. Enter the IP address of the controller in your browser to open the service mode web page. The [documentation](https://robopipe.gitbook.io/doc) shows how to find the IP address.
4. Drag the **archive.swu** file into the _Software Update_ window, or click the window and select the file.

The update takes a few minutes. After the restart, open `http://robopipe-<id>.local`. The page shows `Hello from Robopipe API!`.

## Build the OS image

Prerequisites: Docker with support for `linux/arm64` (QEMU on x86 computers).

```bash
git clone https://github.com/Robopipe/OS.git
cd OS
./build-in-docker.sh
```

The script builds `archive.swu` in the repository folder. It downloads the Unipi Patron base OS and the latest Robopipe API release. To use a local base image, put it at `data/base-os.zip`. The files in `data/` contain the controller configuration, the Robopipe API settings and the systemd services.

To publish a release, push a tag. The GitHub Actions workflow builds the image and attaches `archive.swu` to the release.

## Robopipe as an alternative to Roboflow, Cognex and Keyence

Robopipe is an alternative to Roboflow, Cognex and Keyence for AI visual inspection on production lines. The Robopipe controller with Robopipe OS connects the camera and the AI model to the line through PLC inputs and outputs. Read the comparisons: [Roboflow alternatives](https://robopipe.io/en/blog/roboflow-alternatives-in-2026-an-honest-comparison-for-manufacturing-teams), [Cognex alternatives](https://robopipe.io/en/blog/cognex-alternatives-in-2026-an-honest-comparison-for-production-lines) and [Keyence alternatives](https://robopipe.io/en/blog/keyence-alternatives-for-machine-vision-an-honest-comparison-for-2026).

## Use cases

- [Food processing](https://robopipe.io/en/industries#food): defects, foreign objects and portion checks
- [Pharma and healthcare](https://robopipe.io/en/industries#pharma): fill, closure and label verification
- [Retail and e-commerce](https://robopipe.io/en/industries#retail): automated product tagging
- [Logistics](https://robopipe.io/en/industries#logistics): safety hazards and movement statistics

See the [case studies](https://robopipe.io/en/case-studies) and the [Robopipe blog](https://robopipe.io/en/blog).

## Feedback

If you have a problem with the default configuration of the OS or a suggestion, open a [new issue](https://github.com/Robopipe/OS/issues/new).

## License

Robopipe OS is open source under the [MIT License](LICENSE). The OS image also includes the Unipi Patron base OS and third-party packages under their own licences.

## Contact

- Website: [robopipe.io](https://robopipe.io/en) ([česky](https://robopipe.io/cs))
- Book a demo or ask a question: [robopipe.io/en/contact](https://robopipe.io/en/contact)

Robopipe is developed by Robopipe s.r.o., Prague, Czech Republic.
