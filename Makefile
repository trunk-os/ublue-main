IMAGE_FILE = disk.raw
QCOW2_FILE = disk.qcow2
IMAGE ?= base
CONTAINER_IMAGE ?= localhost/base-main:latest
RAM ?= 8192
CPUS ?= 8
IMAGE_SIZE ?= 50G

image: build-container generate-image

# the make-zfs service should shut the machine down automatically if the VM is run with no
# disks, which is what this does. This just tests that
run:
	qemu-system-x86_64 \
		-m $(RAM) \
		-machine q35 \
		-cpu max \
		-smp cpus=$(CPUS) \
		-boot c \
		-drive file=$(QCOW2_FILE),format=qcow2 

# a vm created for demo purposes. similar to raidz
run-demo:
	@if [ ! -f extra4.raw ]; then make raidz-images; fi
	sudo qemu-system-x86_64 \
		-m $(RAM) \
		-cpu max \
		-machine q35 \
		-smp cpus=$(CPUS) \
		-boot c \
		-net tap \
		-net nic \
		-drive file=$(QCOW2_FILE),format=qcow2 \
		-drive file=extra1.raw,format=raw \
		-drive file=extra2.raw,format=raw \
		-drive file=extra3.raw,format=raw \
		-drive file=extra4.raw,format=raw 

# 4 disk configuration that should automatically get provisioned as raidz
run-raidz:
	@if [ ! -f extra4.raw ]; then make raidz-images; fi
	qemu-system-x86_64 \
		-m $(RAM) \
		-cpu max \
		-machine q35 \
		-smp cpus=$(CPUS) \
		-boot c \
		-drive file=$(QCOW2_FILE),format=qcow2 \
		-drive file=extra1.raw,format=raw \
		-drive file=extra2.raw,format=raw \
		-drive file=extra3.raw,format=raw \
		-drive file=extra4.raw,format=raw 

# 2 disk configuration that should automatically get provisioned as mirror
run-mirror:
	@if [ ! -f extra2.raw ]; then make mirror-images; fi
	qemu-system-x86_64 \
		-m $(RAM) \
		-cpu max \
		-machine q35 \
		-smp cpus=$(CPUS) \
		-boot c \
		-drive file=$(QCOW2_FILE),format=qcow2 \
		-drive file=extra1.raw,format=raw \
		-drive file=extra2.raw,format=raw

# single disk configuration that should automatically get provisioned as zpool and root fs
run-single:
	@if [ ! -f extra1.raw ]; then make single-image; fi
	qemu-system-x86_64 \
		-m $(RAM) \
		-cpu max \
		-machine q35 \
		-smp cpus=$(CPUS) \
		-boot c \
		-drive file=$(QCOW2_FILE),format=qcow2 \
		-drive file=extra1.raw,format=raw

#
# a note about the following truncate calls:
#
# they don't create 50G files, they create sparse files which start at 0 bytes
# consumed and grow to that size potentially. After qemu-img runs for the
# generate-image process, the extra space used in the final image is pruned.
#
# The extra disks always use miniscule actual space unless you put something
# there. And remember, the clean tasks are there for you, too.
# 
#
clean: clean-image clean-extra

clean-image:
	rm -f $(IMAGE_FILE) $(QCOW2_FILE)

clean-extra:
	rm -f extra*.raw

single-image: clean-extra
	truncate -s $(IMAGE_SIZE) extra1.raw

mirror-images: clean-extra
	for i in 1 2; do truncate -s $(IMAGE_SIZE) extra$$i.raw; done

raidz-images: clean-extra
	for i in $$(seq 1 4); do truncate -s $(IMAGE_SIZE) extra$$i.raw; done

# invoke ublue's tooling unprivileged and copy the resulting image to root's
# image store with podman. One of those times docker is much nicer.
#
# You will need the `just` tool (cargo install just) to invoke this task, as
# well as `podman`.
build-container:
	sudo `which just` build-container $(IMAGE)

# generate a bootable raw disk and qcow2 of the operating system for booting
# with qemu. They are equivalent.
#
# You will need `podman` and `qemu-img` (usually in some qemu-tools package) to
# invoke this task.
generate-image: clean
	truncate -s $(IMAGE_SIZE) $(IMAGE_FILE)
	sudo podman run \
		-v ${PWD}:/build \
		-it \
		--pid host \
		--privileged \
		localhost/base-main:latest \
			bootc install to-disk \
				/build/$(IMAGE_FILE) \
				--wipe \
				--filesystem ext4 \
				--generic-image \
				--via-loopback
	qemu-img convert -f raw -O qcow2 $(IMAGE_FILE) $(QCOW2_FILE)

.PHONY: generate-image build-container \
	raidz-images mirror-images single-image \
	clean-extra clean-image clean \
	run-single run-raidz run-mirror \
	run image
