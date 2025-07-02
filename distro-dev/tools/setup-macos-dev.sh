#!/bin/bash
# Setup macOS development environment for LinuxAI distribution building

set -e

echo "🍎 Setting up macOS development environment for LinuxAI..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is for macOS only"
    exit 1
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew already installed"
fi

# Install required development tools
echo "🔧 Installing development tools..."

# Core build tools
brew install \
    wget \
    gnu-tar \
    gnu-sed \
    gnu-grep \
    gawk \
    autoconf \
    automake \
    libtool \
    pkg-config \
    cmake \
    ninja \
    make \
    bison \
    flex \
    texinfo \
    help2man \
    gperf

# Cross-compilation tools
brew install \
    gcc \
    binutils \
    nasm \
    yasm

# ISO creation tools
brew install \
    cdrtools \
    xorriso

# Virtualization for testing
brew install qemu

# Python for AI components
brew install python3

echo "✅ Development environment setup complete!"
echo ""
echo "🔧 Additional setup:"
echo "1. Make sure Command Line Tools are installed:"
echo "   xcode-select --install"
echo ""
echo "2. Set up GNU tools in PATH:"
echo "   export PATH=\"/opt/homebrew/opt/gnu-tar/libexec/gnubin:\$PATH\""
echo "   export PATH=\"/opt/homebrew/opt/gnu-sed/libexec/gnubin:\$PATH\""
echo "   export PATH=\"/opt/homebrew/opt/gnu-grep/libexec/gnubin:\$PATH\""
echo ""
echo "3. Verify installation:"
echo "   make --version"
echo "   gcc --version"
echo "   python3 --version"