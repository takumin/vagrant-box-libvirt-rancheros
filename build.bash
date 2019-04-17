#!/bin/bash
# vim: set noet :

set -eu

# Current Directory
CURRENT_DIR="$(cd "$(dirname "$0")"; pwd)"

# Vendor Directory
VENDOR_DIR="${CURRENT_DIR}/vendor"

# Packer Command
PACKER_CMD="packer"

# Vendor Execute
vendor_execute() {
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
		wget -qO "${VENDOR_DIR}/packer_${PACKER_VERSION}_linux_amd64.zip" \
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
}

# Check Installed Packer
if ! type packer > /dev/null 2>&1; then
	# Install Packer Command
	vendor_execute

	# Set Packer Command Variable
	PACKER_CMD="${VENDOR_DIR}/packer"
fi

# Build Vagrant Box
"${PACKER_CMD}" build "${CURRENT_DIR}/packer.json"
