#!/bin/bash
# LinuxAI Distribution - Cross-compilation toolchain builder
# Builds GCC cross-compiler for multiple architectures

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
SOURCES_DIR="$BUILD_DIR/sources"
TOOLCHAIN_DIR="$BUILD_DIR/toolchain"

# Versions (should match Makefile)
BINUTILS_VERSION="2.41"
GCC_VERSION="13.2.0"
LINUX_VERSION="6.6.8"
GLIBC_VERSION="2.38"

# Supported architectures
ARCHS=(x86_64 aarch64)

# Parallel build jobs
JOBS=${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}

echo "🔧 Building LinuxAI cross-compilation toolchain..."
echo "📁 Build directory: $BUILD_DIR"
echo "🎯 Target architectures: ${ARCHS[*]}"
echo "⚡ Using $JOBS parallel jobs"

# Create directories
mkdir -p "$TOOLCHAIN_DIR"
mkdir -p "$BUILD_DIR/build-toolchain"

# Function to download and extract sources
download_and_extract() {
    local name=$1
    local version=$2
    local url=$3
    local archive="$name-$version.tar.xz"
    
    echo "📥 Downloading $name $version..."
    cd "$SOURCES_DIR"
    
    if [ ! -f "$archive" ]; then
        curl -L -o "$archive" "$url" || {
            echo "❌ Failed to download $archive"
            return 1
        }
    fi
    
    echo "📦 Extracting $archive..."
    if [ ! -d "$name-$version" ]; then
        tar -xf "$archive" || {
            echo "❌ Failed to extract $archive"
            return 1
        }
    fi
}

# Download all required sources
echo "📥 Downloading toolchain sources..."

download_and_extract "binutils" "$BINUTILS_VERSION" \
    "https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz"

download_and_extract "gcc" "$GCC_VERSION" \
    "https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz"

download_and_extract "linux" "$LINUX_VERSION" \
    "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$LINUX_VERSION.tar.xz"

download_and_extract "glibc" "$GLIBC_VERSION" \
    "https://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VERSION.tar.xz"

# Build toolchain for each architecture
for arch in "${ARCHS[@]}"; do
    echo ""
    echo "🏗️  Building toolchain for $arch..."
    
    # Set architecture-specific variables
    case $arch in
        x86_64)
            TARGET="x86_64-linuxai-linux-gnu"
            LINUX_ARCH="x86_64"
            ;;
        aarch64)
            TARGET="aarch64-linuxai-linux-gnu"
            LINUX_ARCH="arm64"
            ;;
        *)
            echo "❌ Unsupported architecture: $arch"
            continue
            ;;
    esac
    
    SYSROOT="$TOOLCHAIN_DIR/$TARGET/sysroot"
    BUILD_ARCH_DIR="$BUILD_DIR/build-toolchain/$arch"
    
    mkdir -p "$SYSROOT"
    mkdir -p "$BUILD_ARCH_DIR"
    
    export PATH="$TOOLCHAIN_DIR/bin:$PATH"
    
    echo "🎯 Target: $TARGET"
    echo "📁 Sysroot: $SYSROOT"
    
    # Step 1: Build Binutils
    echo "🔧 Building binutils for $arch..."
    cd "$BUILD_ARCH_DIR"
    
    if [ ! -d "binutils-build" ]; then
        mkdir binutils-build
        cd binutils-build
        
        "$SOURCES_DIR/binutils-$BINUTILS_VERSION/configure" \
            --target="$TARGET" \
            --prefix="$TOOLCHAIN_DIR" \
            --with-sysroot="$SYSROOT" \
            --disable-nls \
            --disable-werror \
            --enable-gprofng=no
        
        make -j"$JOBS"
        make install
        cd ..
    fi
    
    # Step 2: Install Linux headers
    echo "🐧 Installing Linux headers for $arch..."
    cd "$SOURCES_DIR/linux-$LINUX_VERSION"
    
    make ARCH="$LINUX_ARCH" INSTALL_HDR_PATH="$SYSROOT/usr" headers_install
    
    # Step 3: Build GCC (stage 1 - bootstrap)
    echo "🔧 Building GCC stage 1 for $arch..."
    cd "$BUILD_ARCH_DIR"
    
    if [ ! -d "gcc-stage1-build" ]; then
        mkdir gcc-stage1-build
        cd gcc-stage1-build
        
        # Download GCC prerequisites
        cd "$SOURCES_DIR/gcc-$GCC_VERSION"
        ./contrib/download_prerequisites
        cd "$BUILD_ARCH_DIR/gcc-stage1-build"
        
        "$SOURCES_DIR/gcc-$GCC_VERSION/configure" \
            --target="$TARGET" \
            --prefix="$TOOLCHAIN_DIR" \
            --with-sysroot="$SYSROOT" \
            --with-newlib \
            --without-headers \
            --disable-nls \
            --disable-shared \
            --disable-multilib \
            --disable-decimal-float \
            --disable-threads \
            --disable-libatomic \
            --disable-libgomp \
            --disable-libquadmath \
            --disable-libssp \
            --disable-libvtv \
            --disable-libstdcxx \
            --enable-languages=c,c++
        
        make -j"$JOBS" all-gcc
        make install-gcc
        cd ..
    fi
    
    # Step 4: Build glibc
    echo "📚 Building glibc for $arch..."
    cd "$BUILD_ARCH_DIR"
    
    if [ ! -d "glibc-build" ]; then
        mkdir glibc-build
        cd glibc-build
        
        "$SOURCES_DIR/glibc-$GLIBC_VERSION/configure" \
            --build="$MACHTYPE" \
            --host="$TARGET" \
            --target="$TARGET" \
            --prefix=/usr \
            --with-headers="$SYSROOT/usr/include" \
            --disable-multilib \
            libc_cv_forced_unwind=yes
        
        make install-bootstrap-headers=yes install-headers
        make -j"$JOBS" csu/subdir_lib
        install csu/crt1.o csu/crti.o csu/crtn.o "$SYSROOT/usr/lib/"
        
        "$TOOLCHAIN_DIR/bin/$TARGET-gcc" -nostdlib -nostartfiles -shared -x c /dev/null \
            -o "$SYSROOT/usr/lib/libc.so"
        
        touch "$SYSROOT/usr/include/gnu/stubs.h"
        
        make -j"$JOBS"
        make install
        cd ..
    fi
    
    # Step 5: Build GCC (stage 2 - full)
    echo "🔧 Building GCC stage 2 for $arch..."
    cd "$BUILD_ARCH_DIR"
    
    if [ ! -d "gcc-stage2-build" ]; then
        mkdir gcc-stage2-build
        cd gcc-stage2-build
        
        "$SOURCES_DIR/gcc-$GCC_VERSION/configure" \
            --target="$TARGET" \
            --prefix="$TOOLCHAIN_DIR" \
            --with-sysroot="$SYSROOT" \
            --disable-nls \
            --enable-shared \
            --disable-multilib \
            --enable-languages=c,c++ \
            --enable-c99 \
            --enable-long-long
        
        make -j"$JOBS"
        make install
        cd ..
    fi
    
    echo "✅ Toolchain for $arch completed!"
done

# Create toolchain info file
cat > "$TOOLCHAIN_DIR/toolchain-info.txt" << EOF
LinuxAI Cross-compilation Toolchain
Generated: $(date)
Host: $(uname -a)

Versions:
- Binutils: $BINUTILS_VERSION
- GCC: $GCC_VERSION  
- Linux Headers: $LINUX_VERSION
- Glibc: $GLIBC_VERSION

Supported Architectures:
$(for arch in "${ARCHS[@]}"; do echo "- $arch"; done)

Usage:
export PATH="$TOOLCHAIN_DIR/bin:\$PATH"

Available Compilers:
$(ls "$TOOLCHAIN_DIR/bin/"*-gcc 2>/dev/null || echo "None built yet")
EOF

echo ""
echo "🎉 LinuxAI toolchain build completed!"
echo "📄 Toolchain info: $TOOLCHAIN_DIR/toolchain-info.txt"
echo "🔧 Add to PATH: export PATH=\"$TOOLCHAIN_DIR/bin:\$PATH\""
echo ""
echo "🧪 Test with:"
for arch in "${ARCHS[@]}"; do
    case $arch in
        x86_64) TARGET="x86_64-linuxai-linux-gnu" ;;
        aarch64) TARGET="aarch64-linuxai-linux-gnu" ;;
    esac
    echo "  $TARGET-gcc --version"
done