#!/usr/bin/env bash

set -e

VERSION="8.0.0"
CORES=$(nproc --all)
NOCACHE=""
ARCH=""

# Detect current architecture
detect_arch() {
    local machine=$(uname -m)
    case $machine in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "Unsupported architecture: $machine" >&2
            exit 1
            ;;
    esac
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-cache)
            NOCACHE="--no-cache"
            ;;
        --arch)
            shift
            ARCH="$1"
            if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" && "$ARCH" != "both" ]]; then
                echo "Error: Architecture must be 'amd64', 'arm64', or 'both'"
                exit 1
            fi
            ;;
        --help)
            echo "Usage: $0 [--no-cache] [--arch <amd64|arm64|both>] [--help]"
            echo "  --no-cache       Build without using cache"
            echo "  --arch <arch>    Specify architecture (amd64, arm64, or both)"
            echo "                   If not specified, uses current system architecture"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# If no architecture specified, detect current system architecture
if [ -z "$ARCH" ]; then
    ARCH=$(detect_arch)
    echo "Auto-detected architecture: $ARCH"
fi

echo "Building Suricata Docker images for version ${VERSION}"

build_for_arch() {
    local arch=$1
    echo "Building for ${arch}..."
    
    if [ ! -f "Dockerfile.${arch}" ]; then
        echo "Error: Dockerfile.${arch} not found"
        exit 1
    fi
    
    # Build from parent directory so COPY . copies the entire source code
    docker build ${NOCACHE} \
        --rm \
        --pull \
        --build-arg VERSION=${VERSION} \
        --build-arg CORES=${CORES} \
        --platform linux/${arch} \
        --tag suricata:${VERSION}-${arch} \
        -f ./Dockerfile.${arch} \
        ..
        
    echo "Built: suricata:${VERSION}-${arch}"
}

# Build based on specified or detected architecture
case "$ARCH" in
    amd64)
        build_for_arch "amd64"
        ;;
    arm64)
        build_for_arch "arm64"
        ;;
    both)
        build_for_arch "amd64"
        build_for_arch "arm64"
        ;;
esac

echo "Build completed successfully!"