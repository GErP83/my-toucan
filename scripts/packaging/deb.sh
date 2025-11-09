#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:-}
ARCH=${2:-amd64}
OUT_DIR="build-deb"

# Normalize architecture names for Debian
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
esac

if [[ -z "$VERSION" ]]; then
  echo "❌ ERROR: Version argument missing."
  echo "Usage: $0 <version> [arch]"
  exit 1
fi

echo "📦 Building Toucan DEB for $ARCH version $VERSION"

mkdir -p $OUT_DIR/DEBIAN
mkdir -p $OUT_DIR/usr/local/bin
mkdir -p $OUT_DIR/usr/share/doc/toucan

# Copy binaries (your build process creates them)
cp -a usr/local/bin/* $OUT_DIR/usr/local/bin/ 2>/dev/null || true
cp LICENSE README.md $OUT_DIR/usr/share/doc/toucan/ 2>/dev/null || true

cat > $OUT_DIR/DEBIAN/control <<EOF
Package: toucan
Version: $VERSION
Architecture: $ARCH
Maintainer: Toucan Developers <dev@toucan.app>
Description: Toucan is a static site generator written in Swift.
EOF

dpkg-deb --build $OUT_DIR toucan-linux-$ARCH-$VERSION.deb
mv toucan-linux-$ARCH-$VERSION.deb build-deb/

DEB_FILE="build-deb/toucan-linux-$ARCH-$VERSION.deb"
if [[ ! -f "$DEB_FILE" ]]; then
  echo "❌ ERROR: DEB not created!"
  exit 1
fi

echo "🧪 Verifying DEB..."
dpkg-deb --info "$DEB_FILE"
dpkg-deb --contents "$DEB_FILE"

sha256sum "$DEB_FILE" > "build-deb/toucan-linux-$ARCH-$VERSION.sha256"
echo "✅ DEB build complete for $ARCH"


#set -e

#VERSION="$1"
#NAME="toucan"

#if [ -z "$VERSION" ]; then
#  echo "Usage: $0 <VERSION>"
#  exit 1
#fi

#ARCH="amd64"
#BUILD_DIR="build-deb"
#PKG_ROOT="$BUILD_DIR/${NAME}_${VERSION}"
#INSTALL_PREFIX="/usr/local/bin"
#BIN_DIR=".build/release"
#BINARY_NAMES=("toucan" "toucan-generate" "toucan-init" "toucan-serve" "toucan-watch")

#echo "📦 Building .deb for $NAME version $VERSION"

# Collect matching executables
#EXECUTABLES=""
#for BINNAME in "${BINARY_NAMES[@]}"; do
#  CANDIDATE="$BIN_DIR/$BINNAME"
#  if [ -f "$CANDIDATE" ] && [ -x "$CANDIDATE" ]; then
#    EXECUTABLES+="$CANDIDATE"$'\n'
#  else
#    echo "⚠️ Skipping missing or non-executable: $BINNAME"
#  fi
#done

#if [ -z "$EXECUTABLES" ]; then
#  echo "❌ No executable binaries found"
#  exit 1
#fi

# Prepare package directory structure
#rm -rf "$PKG_ROOT"
#mkdir -p "$PKG_ROOT/DEBIAN"
#mkdir -p "$PKG_ROOT$INSTALL_PREFIX"

# Copy binaries
#while IFS= read -r BIN; do
#  [ -z "$BIN" ] && continue
#  BASENAME=$(basename "$BIN")
#  cp "$BIN" "$PKG_ROOT$INSTALL_PREFIX/$BASENAME"
#  chmod +x "$PKG_ROOT$INSTALL_PREFIX/$BASENAME"
#  echo "✅ Added $BASENAME"
#done <<< "$EXECUTABLES"

#cat > "$PKG_ROOT/DEBIAN/control" <<EOF
#Package: $NAME
#Version: $VERSION
#Architecture: $ARCH
#Maintainer: binarybirds <info@binarybirds.com>
#Description: $NAME is a static site generator written in Swift.
#Section: utils
#Priority: optional
#EOF

#dpkg-deb --build "$PKG_ROOT"
#CUSTOM_NAME="toucan-linux-amd64-${VERSION}.deb"
#mv "$PKG_ROOT.deb" "$BUILD_DIR/$CUSTOM_NAME"
#echo "🎉 DEB created: $BUILD_DIR/$CUSTOM_NAME"