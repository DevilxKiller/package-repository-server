#!/bin/bash
set -e

echo "=== Package Repository Server ==="
echo "Initializing..."

# Create required directories
mkdir -p \
    "$REPO_DATA_DIR/deb/pool/main" \
    "$REPO_DATA_DIR/deb/dists/stable/main/binary-amd64" \
    "$REPO_DATA_DIR/deb/dists/stable/main/binary-arm64" \
    "$REPO_DATA_DIR/rpm/x86_64" \
    "$REPO_DATA_DIR/rpm/aarch64" \
    "$REPO_DATA_DIR/arch/x86_64" \
    "$REPO_DATA_DIR/arch/aarch64" \
    "$REPO_DATA_DIR/alpine/v3.19/main/x86_64" \
    "$REPO_DATA_DIR/alpine/v3.19/main/aarch64" \
    "$REPO_GPG_DIR" \
    /var/log/package-repo \
    /etc/ferron

# Copy default Ferron config if not mounted
if [ ! -f /etc/ferron/ferron.yaml ]; then
    cat > /etc/ferron/ferron.yaml <<EOF
global:
  serverAdministratorEmail: "admin@localhost"
  enableLogging: true
  logFilePath: "/var/log/package-repo/ferron-access.log"
  errorLogFilePath: "/var/log/package-repo/ferron-error.log"
  enableCompression: true

server:
  - listen: 80
    serverNames:
      - "*"
    locations:
      - path: "/repo.gpg"
        root: "/data/packages"
      - path: "/setup/"
        proxy:
          host: "127.0.0.1"
          port: 8080
          path: "/setup/"
      - path: "/api/"
        proxy:
          host: "127.0.0.1"
          port: 8080
          path: "/api/"
        clientMaxBodySize: 524288000
      - path: "/health"
        proxy:
          host: "127.0.0.1"
          port: 8080
          path: "/health"
      - path: "/ready"
        proxy:
          host: "127.0.0.1"
          port: 8080
          path: "/ready"
      - path: "/deb/"
        root: "/data/packages/deb"
        directoryListing: true
      - path: "/rpm/"
        root: "/data/packages/rpm"
        directoryListing: true
      - path: "/arch/"
        root: "/data/packages/arch"
        directoryListing: true
      - path: "/alpine/"
        root: "/data/packages/alpine"
        directoryListing: true
EOF
fi

# Initialize GPG if no key exists
if [ ! -f "$REPO_GPG_DIR/private.key" ]; then
    echo "Generating GPG key for package signing..."

    cat > /tmp/gpg-batch <<EOF
%echo Generating package signing key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Package Repository
Name-Email: repo@localhost
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF

    gpg --batch --gen-key /tmp/gpg-batch
    rm /tmp/gpg-batch

    GPG_KEY_ID=$(gpg --list-keys --keyid-format long | grep -A1 "^pub" | tail -1 | awk '{print $1}')
    gpg --armor --export "$GPG_KEY_ID" > "$REPO_GPG_DIR/public.key"
    gpg --armor --export-secret-keys "$GPG_KEY_ID" > "$REPO_GPG_DIR/private.key"
    echo "$GPG_KEY_ID" > "$REPO_GPG_DIR/key-id"

    echo "GPG key generated: $GPG_KEY_ID"
else
    echo "Using existing GPG key..."
    if ! gpg --list-keys 2>/dev/null | grep -q "Package Repository"; then
        gpg --import "$REPO_GPG_DIR/public.key" 2>/dev/null || true
        gpg --import "$REPO_GPG_DIR/private.key" 2>/dev/null || true
    fi
fi

# Copy public key to web-accessible location
cp "$REPO_GPG_DIR/public.key" "$REPO_DATA_DIR/repo.gpg"

# Initialize empty repositories if they don't exist
if [ ! -f "$REPO_DATA_DIR/deb/dists/stable/Release" ]; then
    echo "Initializing APT repository..."
    process-deb init
fi

if [ ! -f "$REPO_DATA_DIR/rpm/x86_64/repodata/repomd.xml" ]; then
    echo "Initializing RPM repository..."
    process-rpm init
fi

if [ ! -f "$REPO_DATA_DIR/arch/x86_64/custom.db" ]; then
    echo "Initializing Arch repository..."
    process-arch init
fi

if [ ! -f "$REPO_DATA_DIR/alpine/v3.19/main/x86_64/APKINDEX.tar.gz" ]; then
    echo "Initializing Alpine repository..."
    process-alpine init
fi

echo "Repository initialization complete."
echo ""
echo "Repository URLs:"
echo "  APT:    http://localhost/deb"
echo "  RPM:    http://localhost/rpm"
echo "  Arch:   http://localhost/arch"
echo "  Alpine: http://localhost/alpine"
echo ""
echo "API Server: http://localhost:8080"
echo ""

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisord.conf
