#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:-}
ARCH=${2:-x86_64}
OUT_DIR="build-rpm"
SPEC_FILE="scripts/packaging/toucan.spec"

# Normalize architecture name for RPM
case "$ARCH" in
  arm64) ARCH="aarch64" ;;
  amd64) ARCH="x86_64" ;;
esac

# --- Validate input ---
if [[ -z "$VERSION" ]]; then
  echo "❌ ERROR: Version argument missing."
  echo "Usage: $0 <version> [arch]"
  exit 1
fi

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "❌ ERROR: Spec file not found at $SPEC_FILE"
  exit 1
fi

echo "📦 Building Toucan RPM for $ARCH version $VERSION"

# Ensure staging area matches .spec expectations
mkdir -p $OUT_DIR/usr/local/bin
mkdir -p $OUT_DIR/SOURCES

# Copy prebuilt binaries (your build process already creates them)
cp -a usr/local/bin/* $OUT_DIR/usr/local/bin/ 2>/dev/null || true
cp LICENSE README.md $OUT_DIR/ 2>/dev/null || true

rpmbuild \
  -bb "$SPEC_FILE" \
  --define "_topdir $(pwd)/$OUT_DIR" \
  --define "version $VERSION" \
  --target "$ARCH"

RPM_FILE="$OUT_DIR/RPMS/$ARCH/toucan-linux-$ARCH-$VERSION.rpm"
if [[ ! -f "$RPM_FILE" ]]; then
  echo "❌ ERROR: RPM not created!"
  exit 1
fi

mv "$RPM_FILE" "$OUT_DIR/toucan-linux-$ARCH-$VERSION.rpm"

echo "🧪 Verifying RPM..."
rpm -Kv "$OUT_DIR/toucan-linux-$ARCH-$VERSION.rpm"
rpm -qp "$OUT_DIR/toucan-linux-$ARCH-$VERSION.rpm" || true

sha256sum "$OUT_DIR/toucan-linux-$ARCH-$VERSION.rpm" > "$OUT_DIR/toucan-linux-$ARCH-$VERSION.sha256"
echo "✅ RPM build complete for $ARCH"


#set -e

#VERSION="$1"
#NAME="toucan"

#if [ -z "$VERSION" ]; then
#  echo "Usage: $0 <VERSION>"
#  exit 1
#fi

#TARBALL="${NAME}-${VERSION}.tar.gz"
#TOPDIR="$HOME/rpmbuild"
#BIN_DIR=".build/release"
#BUILD_DIR="build-rpm"
#BINARY_NAMES=("toucan" "toucan-generate" "toucan-init" "toucan-serve" "toucan-watch")

#echo "📦 Building RPM for $NAME version $VERSION"

# Prepare RPM directories
#mkdir -p "$TOPDIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
#mkdir -p "$BUILD_DIR"
#WORKDIR=$(mktemp -d)
#trap 'rm -rf "$WORKDIR"' EXIT

# Stage binaries
#SRC_DIR="$WORKDIR/${NAME}-${VERSION}/usr/local/bin"
#mkdir -p "$SRC_DIR"
#EXECUTABLES=()

#for BIN in "${BINARY_NAMES[@]}"; do
#  SRC="$BIN_DIR/$BIN"
#  if [ -x "$SRC" ]; then
#    cp "$SRC" "$SRC_DIR/"
#    chmod +x "$SRC_DIR/$BIN"
#    EXECUTABLES+=("$BIN")
#    echo "✅ Staged: $BIN"
#  else
#    echo "⚠️ Skipped: $BIN"
#  fi
#done

#if [ ${#EXECUTABLES[@]} -eq 0 ]; then
#  echo "❌ No valid executables found"
#  exit 1
#fi

# Optionally include license file and readme file
#cp -f LICENSE README.md "$WORKDIR/${NAME}-${VERSION}/" 2>/dev/null || echo "ℹ️ File(s) not found"

# Create source tarball for rpmbuild
#tar -czf "$TOPDIR/SOURCES/$TARBALL" -C "$WORKDIR" "${NAME}-${VERSION}"

# Copy .spec file
#cp "./scripts/packaging/${NAME}.spec" "$TOPDIR/SPECS/"

# Build the RPM
#rpmbuild -ba "$TOPDIR/SPECS/${NAME}.spec" --define "ver $VERSION"

# Copy and rename RPM
#FINAL_RPM=$(find "$TOPDIR/RPMS" -type f -name "*.rpm" | head -n1)
#RPM_OUTPUT="$BUILD_DIR/${NAME}-linux-x86_64-${VERSION}.rpm"
#cp "$FINAL_RPM" "$RPM_OUTPUT"
#echo "🎉 RPM created: $RPM_OUTPUT"

# Create ZIP of raw binaries
#ZIP_NAME="${NAME}-linux-${VERSION}.zip"
#SHA_NAME="${NAME}-linux-${VERSION}.sha256"
#ZIP_DIR="$BUILD_DIR/bin"

#rm -rf "$ZIP_DIR"
#mkdir -p "$ZIP_DIR"

#for BIN in "${EXECUTABLES[@]}"; do
#  cp "$BIN_DIR/$BIN" "$ZIP_DIR/"
#done

#cd "$ZIP_DIR"
#zip "../$ZIP_NAME" ./*
#cd - >/dev/null

# Create SHA256
#cd "$BUILD_DIR"
#shasum -a 256 "$ZIP_NAME" > "$SHA_NAME"
#cd - >/dev/null

#echo "✅ ZIP created: $BUILD_DIR/$ZIP_NAME"
#echo "✅ SHA256 created: $BUILD_DIR/$SHA_NAME"
