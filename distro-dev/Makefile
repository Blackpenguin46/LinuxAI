# LinuxAI Distribution Build System
# Multi-architecture Linux distribution with AI integration

# Configuration
DISTRO_NAME = LinuxAI
VERSION = 0.1.0-alpha
BUILD_DIR = $(PWD)/build
TOOLCHAIN_DIR = $(BUILD_DIR)/toolchain
SYSROOT_DIR = $(BUILD_DIR)/sysroot
ISO_DIR = $(BUILD_DIR)/iso

# Architectures to support
ARCHS = x86_64 aarch64
KERNEL_VERSION = 6.6.8
GLIBC_VERSION = 2.38
BINUTILS_VERSION = 2.41
GCC_VERSION = 13.2.0

# Parallel build jobs
JOBS = $(shell sysctl -n hw.ncpu 2>/dev/null || echo 4)

.PHONY: all clean setup-dev-env build-toolchain build-base build-kernel build-ai-core build-iso setup-vm test-vm easy-install

all: setup-dev-env build-toolchain build-base build-ai-core build-iso

# Development environment setup
setup-dev-env:
	@echo "Setting up LinuxAI development environment..."
	mkdir -p $(BUILD_DIR)/{sources,toolchain,sysroot,iso}
	mkdir -p src/{kernel,base-system,ai-core,packages}
	mkdir -p tools/{build-scripts,iso-builder}
	@echo "Installing required development packages..."
	# This will need to be customized based on host system

# Download sources
download-sources:
	@echo "Downloading source packages..."
	mkdir -p $(BUILD_DIR)/sources
	# Download kernel, glibc, binutils, gcc, etc. (skip if already exists)
	cd $(BUILD_DIR)/sources && \
	[ ! -f linux-$(KERNEL_VERSION).tar.xz ] && curl -L -o linux-$(KERNEL_VERSION).tar.xz https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(KERNEL_VERSION).tar.xz || echo "Linux sources already downloaded" && \
	[ ! -f glibc-$(GLIBC_VERSION).tar.xz ] && curl -L -o glibc-$(GLIBC_VERSION).tar.xz https://ftp.gnu.org/gnu/glibc/glibc-$(GLIBC_VERSION).tar.xz || echo "Glibc sources already downloaded" && \
	[ ! -f binutils-$(BINUTILS_VERSION).tar.xz ] && curl -L -o binutils-$(BINUTILS_VERSION).tar.xz https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz || echo "Binutils sources already downloaded" && \
	[ ! -f gcc-$(GCC_VERSION).tar.xz ] && curl -L -o gcc-$(GCC_VERSION).tar.xz https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz || echo "GCC sources already downloaded"

# Build cross-compilation toolchain
build-toolchain: download-sources
	@echo "Building cross-compilation toolchain..."
	./tools/build-scripts/build-toolchain.sh

# Build base system (LFS-style)
build-base: build-toolchain
	@echo "Building base system..."
	./tools/build-scripts/build-base-system.sh

# Build custom kernel with AI support
build-kernel:
	@echo "Building custom kernel with AI drivers..."
	./tools/build-scripts/build-kernel.sh

# Build AI core system
build-ai-core: build-base
	@echo "Building AI core system..."
	./tools/build-scripts/build-ai-core.sh

# Create bootable ISO
build-iso: build-base build-kernel build-ai-core
	@echo "Creating bootable ISO..."
	./tools/iso-builder/create-iso.sh

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf src/*/build

# Development targets
dev-shell:
	@echo "Starting development shell with environment variables..."
	export LFS=$(BUILD_DIR)/sysroot && \
	export PATH=$(TOOLCHAIN_DIR)/bin:$$PATH && \
	bash

# Quick test in QEMU
test-iso:
	qemu-system-x86_64 -cdrom $(ISO_DIR)/$(DISTRO_NAME)-$(VERSION)-x86_64.iso -m 2048 -enable-kvm

# Virtual Machine Testing
setup-vm:
	@echo "Setting up VM testing environment..."
	./tools/vm-testing/vm-setup.sh

test-vm: build-iso setup-vm
	@echo "Starting LinuxAI in virtual machine..."
	./vm-testing/vm-manager.sh start

# Easy Installation
easy-install:
	@echo "Launching LinuxAI easy installer..."
	./tools/user-setup/easy-install.sh

# Help target
help:
	@echo "LinuxAI Distribution Build System"
	@echo "Available targets:"
	@echo ""
	@echo "🏗️  Build targets:"
	@echo "  all           - Build complete distribution"
	@echo "  setup-dev-env - Set up development environment"
	@echo "  build-toolchain - Build cross-compilation tools"
	@echo "  build-base    - Build base system"
	@echo "  build-kernel  - Build custom kernel"
	@echo "  build-ai-core - Build AI integration"
	@echo "  build-iso     - Create bootable ISO"
	@echo ""
	@echo "🧪 Testing targets:"
	@echo "  setup-vm      - Set up VM testing environment"
	@echo "  test-vm       - Test LinuxAI in virtual machine"
	@echo "  test-iso      - Test ISO in QEMU"
	@echo ""
	@echo "📦 User targets:"
	@echo "  easy-install  - Launch user-friendly installer"
	@echo ""
	@echo "🧹 Maintenance:"
	@echo "  clean         - Clean build artifacts"