# srk's makefile for the DSM lab
.PHONY: default build-if-needed run

# by default, use Stephen's statically linked build of qemu 6.1
QEMU ?= /home/k2144518/6CCS3DSM/qemu-system-6.1.0-static/bin/qemu-system-x86_64

# it is suggested to boot qemu using a Debian image provided by Stephen
QEMU_BACKING_IMAGE ?= /home/k2144518/6CCS3DSM/debian-base.img

# to allow local modifications within qemu that don't modify the backing image,
# create a qcow2 "top layer" that names Stephen's image as its backing.
# This is a prefabricated such qcow2 file, which we will copy to our home directory.
QEMU_TOP_LAYER_IMG_TEMPLATE ?= /home/k2144518/6CCS3DSM/debian-top-layer.qcow2

# the image we will make as a copy of Stephen's empty top layer
QEMU_IMG ?= dsm-debian-top-layer.qcow2

# Stephen's build of unfsd
UNFS3 ?= /home/k2144518/6CCS3DSM/unfsd

default: run

exports:
	d=$$(mktemp -d) && \
	echo "Warning: creating a default 'exports' file exporting $${d}" 1>&2; \
	echo "$${d} (rw,insecure)" > $@

# only try to build the binary if we can't find it locally
# FIXME: reproduce the build instructions from bootstrap onwards, since 'Makefile' needs generating
build-if-needed:
	test -x $(UNFS3) || \
{ echo "Server binary $(UNFS3) not found, so attempting a build from source..." 1>&2; $(MAKE) all; }

# we run the server in the background
run: build-if-needed exports
	( $(UNFS3) -u -d -e $$(pwd)/exports -n 4711 -m 4711 -p & )

# if we don't yet have an image file, copy Stephen's qcow2 top layer that references the backing file
$(QEMU_IMG):
	cp $(QEMU_TOP_LAYER_IMG_TEMPLATE) $@

# boot qemu using the serial console
boot-qemu: $(QEMU) $(QEMU_IMG)
	$(QEMU) -m 1024 -drive format=raw,file=$(QEMU_IMG) \
    -nographic \
    -serial mon:stdio \
    -netdev user,id=mynet0,restrict=no \
    -device e1000,netdev=mynet0 \
    -object filter-dump,id=f1,netdev=mynet0,file=netdump.pcap

# the upstream makefile includes an 'all' target that builds the daemon
-include Makefile
