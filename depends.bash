#!/bin/bash
# vim: set noet :

set -eu

# Vendor Directory
VENDOR_DIR="$(cd "$(dirname "$0")"; pwd)/vendor"

# Check Packer Version
if [ -z "${PACKER_VERSION}" ]; then
	echo "Require Environment Variable: PACKER_VERSION"
	exit 1
fi

# Create Vendor Directory
if [ ! -d "${VENDOR_DIR}" ]; then
	mkdir -p "${VENDOR_DIR}"
fi

# Download Packer Archive
if [ ! -f "${VENDOR_DIR}/packer_${PACKER_VERSION}_linux_amd64.zip" ]; then
	wget -O "${VENDOR_DIR}/packer_${PACKER_VERSION}_linux_amd64.zip" \
		"https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"
fi

# Extract Packer Archive
if [ ! -f "${VENDOR_DIR}/packer" ]; then
	unzip -d "${VENDOR_DIR}" "${VENDOR_DIR}/packer_${PACKER_VERSION}_linux_amd64.zip"
fi

# Permission Packer Binary
if [ ! -x "${VENDOR_DIR}/packer" ]; then
	chmod +x "${VENDOR_DIR}/packer"
fi
