# Trunk

This is a fork of ublue-main to support trunkos development

All custom tasks are in a makefile. You will need several tools to use them:

- `just`: `cargo install just`. Requires a [rust environment](https://rustup.rs). Use a package if you can.
- `podman`: redhat container tool. Use a package.

## Make tasks

To run these takes, use `make <taskname>`. Combine them for ease, e.g.: `make clean image run-raidz`.

- clean: remove all lingering disk images
- clean-image: remove system images
- clean-extra: remove extra images (simulates local disk in hardware)
- raidz-images: generate 4 images which should be detected and built as a raidz when booted with `make run-raidz`
- mirror-images: generate 2 images which should be detected and built as a mirror when booted with `make run-mirror`
- single-image: generate a single image which should be detected and built as a single-volume zpool when booted with `make run-single`
- run: run a qemu VM with just the system image and no extra images. **NOTE**: the system is currently configured to shut this host down as it assumes there is no real disk to provision.
- run-single: run a qemu VM with a single extra drive. The ZFS step should create a zpool and mount it under /trunk, create several datasets and volumes and mount them within the filesystem.
- run-mirror: run a qemu VM with a 2 extra drives. The ZFS step should create a mirrored zpool and mount it under /trunk, create several datasets and volumes and mount them within the filesystem.
- run-raidz: run a qemu VM with a 4 extra drives. The ZFS step should create a raidz zpool and mount it under /trunk, create several datasets and volumes and mount them within the filesystem.
- build-container: builds the container image from instructions; this will be used to create the final disk image.
- generate-image: (re)create a raw and qcow2 VM image from the container image
- image: combination of build-container and generate-image

# Main

[![build-41](https://github.com/ublue-os/main/actions/workflows/build-41.yml/badge.svg)](https://github.com/ublue-os/main/actions/workflows/build-41.yml)
[![build-42](https://github.com/ublue-os/main/actions/workflows/build-42.yml/badge.svg)](https://github.com/ublue-os/main/actions/workflows/build-42.yml)

A common main image for all other uBlue images, with minimal (but important) adjustments to Fedora. <3

# Documentation

- [Main website](https://universal-blue.org)
- [Documentation](https://universal-blue.org/documentation.html)
- [Scope document](https://universal-blue.org/mission.html)
