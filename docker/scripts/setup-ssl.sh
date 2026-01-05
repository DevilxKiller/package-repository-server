#!/bin/bash
# SSL Certificate Setup Script
# Supports: Let's Encrypt (automatic) or manual certificates

set -e

CERT_DIR="${CERT_DIR:-/data/certs}"
ACME_DIR="${ACME_DIR:-/data/acme}"
DOMAIN="${DOMAIN:-}"
EMAIL="${ADMIN_EMAIL:-admin@localhost}"

usage() {
    echo "Usage: setup-ssl.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  letsencrypt    Obtain certificate from Let's Encrypt"
    echo "  selfsigned     Generate self-signed certificate"
    echo "  manual         Show manual certificate installation instructions"
    echo "  renew          Renew Let's Encrypt certificate"
    echo "  status         Show certificate status"
    echo ""
    echo "Environment variables:"
    echo "  DOMAIN         Domain name (required for letsencrypt)"
    echo "  ADMIN_EMAIL    Email for Let's Encrypt notifications"
    echo "  CERT_DIR       Certificate directory (default: /data/certs)"
    echo ""
}

check_domain() {
    if [ -z "$DOMAIN" ]; then
        echo "Error: DOMAIN environment variable is required"
        echo "Example: DOMAIN=packages.example.com ./setup-ssl.sh letsencrypt"
        exit 1
    fi
}

install_certbot() {
    if ! command -v certbot &> /dev/null; then
        echo "Installing certbot..."
        apk add --no-cache certbot
    fi
}

letsencrypt() {
    check_domain
    install_certbot

    echo "Obtaining Let's Encrypt certificate for $DOMAIN..."

    mkdir -p "$CERT_DIR" "$ACME_DIR/.well-known/acme-challenge"

    # Use webroot authentication (Ferron must be running on port 80)
    certbot certonly \
        --webroot \
        --webroot-path="$ACME_DIR" \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domain "$DOMAIN" \
        --cert-path "$CERT_DIR/cert.pem" \
        --key-path "$CERT_DIR/privkey.pem" \
        --fullchain-path "$CERT_DIR/fullchain.pem"

    # Copy certificates to expected location
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem "$CERT_DIR/fullchain.pem"
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem "$CERT_DIR/privkey.pem"

    echo ""
    echo "Certificate obtained successfully!"
    echo "Certificate: $CERT_DIR/fullchain.pem"
    echo "Private key: $CERT_DIR/privkey.pem"
    echo ""
    echo "To enable HTTPS, update your Ferron config to use ferron-tls.yaml"
    echo "and restart the server."
}

selfsigned() {
    DOMAIN="${DOMAIN:-localhost}"

    echo "Generating self-signed certificate for $DOMAIN..."

    mkdir -p "$CERT_DIR"

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/privkey.pem" \
        -out "$CERT_DIR/fullchain.pem" \
        -subj "/CN=$DOMAIN/O=Package Repository/C=US" \
        -addext "subjectAltName=DNS:$DOMAIN,DNS:localhost,IP:127.0.0.1"

    echo ""
    echo "Self-signed certificate generated!"
    echo "Certificate: $CERT_DIR/fullchain.pem"
    echo "Private key: $CERT_DIR/privkey.pem"
    echo ""
    echo "Note: Self-signed certificates will show browser warnings."
    echo "For production, use Let's Encrypt instead."
}

renew() {
    install_certbot

    echo "Renewing Let's Encrypt certificates..."

    certbot renew --webroot --webroot-path="$ACME_DIR"

    # Copy renewed certificates
    if [ -n "$DOMAIN" ] && [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem "$CERT_DIR/fullchain.pem"
        cp /etc/letsencrypt/live/$DOMAIN/privkey.pem "$CERT_DIR/privkey.pem"
        echo "Certificates renewed and copied."
    fi
}

status() {
    echo "Certificate Status"
    echo "=================="
    echo ""

    if [ -f "$CERT_DIR/fullchain.pem" ]; then
        echo "Certificate found: $CERT_DIR/fullchain.pem"
        echo ""
        openssl x509 -in "$CERT_DIR/fullchain.pem" -noout -subject -dates -issuer
    else
        echo "No certificate found at $CERT_DIR/fullchain.pem"
    fi
}

manual() {
    echo "Manual Certificate Installation"
    echo "================================"
    echo ""
    echo "1. Obtain your SSL certificate from your CA"
    echo ""
    echo "2. Place your certificate files in $CERT_DIR/:"
    echo "   - fullchain.pem  (certificate + intermediate certs)"
    echo "   - privkey.pem    (private key)"
    echo ""
    echo "3. Use the TLS configuration:"
    echo "   cp config/ferron-tls.yaml config/ferron.yaml"
    echo ""
    echo "4. Set the DOMAIN environment variable:"
    echo "   export DOMAIN=packages.example.com"
    echo ""
    echo "5. Restart the server"
    echo ""
}

# Main
case "${1:-}" in
    letsencrypt|le|acme)
        letsencrypt
        ;;
    selfsigned|self)
        selfsigned
        ;;
    renew)
        renew
        ;;
    status)
        status
        ;;
    manual)
        manual
        ;;
    *)
        usage
        exit 1
        ;;
esac
