# Robopipe OS

This repository contains set of scripts and tools to build Robopipe OS images. It also contains
pre-built OS images in the [release section](https://github.com/Robopipe/OS/releases) of this repository,
that can be readily installed on Robopipe controller.

## Installing the OS

Follow these instructions to install the latest version of Robopipe OS on your controller (more detailed version can be found at [Robopipe docs](https://robopipe.gitbook.io/robopipe)):

- Start your controller in service mode
  - Turn off the controller
  - Press and hold the _SERVICE_ button on your controller (usually located next to USB labels)
  - Turn on the controller while still hodling the _SERVICE_ button
  - Release the _SERVICE_ button when all the LEDs start blinking periodically
- Download the [latest release of Robopipe OS](https://github.com/Robopipe/OS/releases/latest)
  - Download the **archive.swu** file
- Open the service mode website in your browser
  - Enter the IP address of your controller into your browser (check our [docs](https://robopipe.gitbook.io/robopipe) to see how to find your controller's IP address)
- Upload the **archive.swu** file into the _Software Update_ window
  - Drag and drop the file into the window or click on the window and select the files from your files

That's all! The update shall take a few minutes at maximum for everything to become functioning again.

## Feedback

If you encounter any problems with the default configuration of the OS or have any
suggestions, please open a [new issue](https://github.com/Robopipe/OS/issues/new).
