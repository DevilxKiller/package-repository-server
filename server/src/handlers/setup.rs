use actix_web::{web, HttpRequest, HttpResponse, Responder};

/// Returns a shell script for easy APT repository setup
pub async fn apt_setup(req: HttpRequest) -> impl Responder {
    let host = req
        .headers()
        .get("Host")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("localhost");

    let scheme = req
        .headers()
        .get("X-Forwarded-Proto")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("http");

    let script = format!(
        r#"#!/bin/bash
# Package Repository - APT Setup Script
# Usage: curl -fsSL {scheme}://{host}/setup/apt | sudo bash

set -e

REPO_URL="{scheme}://{host}"
KEYRING_PATH="/usr/share/keyrings/package-repo.gpg"
LIST_PATH="/etc/apt/sources.list.d/package-repo.list"

echo "Setting up APT repository from $REPO_URL..."

# Download and install GPG key
echo "Downloading GPG key..."
curl -fsSL "$REPO_URL/repo.gpg" | gpg --dearmor -o "$KEYRING_PATH"

# Add repository
echo "Adding repository..."
cat > "$LIST_PATH" << EOF
deb [signed-by=$KEYRING_PATH] $REPO_URL/deb stable main
EOF

# Update package lists
echo "Updating package lists..."
apt-get update

echo ""
echo "Done! Repository configured successfully."
echo "You can now install packages with: apt install <package-name>"
"#,
        scheme = scheme,
        host = host
    );

    HttpResponse::Ok()
        .content_type("text/x-shellscript")
        .body(script)
}

/// Returns a shell script for easy YUM/DNF repository setup
pub async fn rpm_setup(req: HttpRequest) -> impl Responder {
    let host = req
        .headers()
        .get("Host")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("localhost");

    let scheme = req
        .headers()
        .get("X-Forwarded-Proto")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("http");

    let script = format!(
        r#"#!/bin/bash
# Package Repository - YUM/DNF Setup Script
# Usage: curl -fsSL {scheme}://{host}/setup/rpm | sudo bash

set -e

REPO_URL="{scheme}://{host}"

echo "Setting up YUM/DNF repository from $REPO_URL..."

# Create repo file
cat > /etc/yum.repos.d/package-repo.repo << EOF
[package-repo]
name=Package Repository
baseurl=$REPO_URL/rpm/\$basearch/
enabled=1
gpgcheck=1
gpgkey=$REPO_URL/repo.gpg
EOF

# Import GPG key
echo "Importing GPG key..."
rpm --import "$REPO_URL/repo.gpg"

# Update cache
echo "Updating package cache..."
if command -v dnf &> /dev/null; then
    dnf makecache
else
    yum makecache
fi

echo ""
echo "Done! Repository configured successfully."
echo "You can now install packages with: dnf install <package-name>"
"#,
        scheme = scheme,
        host = host
    );

    HttpResponse::Ok()
        .content_type("text/x-shellscript")
        .body(script)
}

/// Returns a shell script for easy Pacman repository setup
pub async fn arch_setup(req: HttpRequest) -> impl Responder {
    let host = req
        .headers()
        .get("Host")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("localhost");

    let scheme = req
        .headers()
        .get("X-Forwarded-Proto")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("http");

    let script = format!(
        r#"#!/bin/bash
# Package Repository - Pacman Setup Script
# Usage: curl -fsSL {scheme}://{host}/setup/arch | sudo bash

set -e

REPO_URL="{scheme}://{host}"

echo "Setting up Pacman repository from $REPO_URL..."

# Check if already configured
if grep -q "package-repo" /etc/pacman.conf 2>/dev/null; then
    echo "Repository already configured in /etc/pacman.conf"
else
    # Add repository to pacman.conf
    echo "Adding repository to /etc/pacman.conf..."
    cat >> /etc/pacman.conf << EOF

[package-repo]
SigLevel = Optional TrustAll
Server = $REPO_URL/arch/\$arch
EOF
fi

# Sync databases
echo "Syncing package databases..."
pacman -Sy

echo ""
echo "Done! Repository configured successfully."
echo "You can now install packages with: pacman -S <package-name>"
"#,
        scheme = scheme,
        host = host
    );

    HttpResponse::Ok()
        .content_type("text/x-shellscript")
        .body(script)
}

/// Returns a shell script for easy APK repository setup
pub async fn alpine_setup(req: HttpRequest) -> impl Responder {
    let host = req
        .headers()
        .get("Host")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("localhost");

    let scheme = req
        .headers()
        .get("X-Forwarded-Proto")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("http");

    let script = format!(
        r#"#!/bin/bash
# Package Repository - APK Setup Script
# Usage: curl -fsSL {scheme}://{host}/setup/alpine | sh

set -e

REPO_URL="{scheme}://{host}"

echo "Setting up APK repository from $REPO_URL..."

# Download GPG key
echo "Downloading repository key..."
wget -qO /etc/apk/keys/package-repo.rsa.pub "$REPO_URL/repo.gpg"

# Add repository if not already present
if ! grep -q "$REPO_URL/alpine" /etc/apk/repositories 2>/dev/null; then
    echo "Adding repository..."
    echo "$REPO_URL/alpine/v3.19/main" >> /etc/apk/repositories
fi

# Update package index
echo "Updating package index..."
apk update

echo ""
echo "Done! Repository configured successfully."
echo "You can now install packages with: apk add <package-name>"
"#,
        scheme = scheme,
        host = host
    );

    HttpResponse::Ok()
        .content_type("text/x-shellscript")
        .body(script)
}
