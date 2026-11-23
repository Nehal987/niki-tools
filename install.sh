#!/data/data/com.termux/files/usr/bin/bash
# One-shot Termux installer for niki_tools (AArch64 Android)
# - Installs required Termux packages (libffi, libexpat, openssl, ca-certificates, curl)
# - Copies niki_tools to /sdcard/Download/niki_tools AND installs executable ~/niki_tools
# - Creates ~/tools (and $PREFIX/bin/tools) so users run: ./tools start

set -euo pipefail

# Default GitHub raw binary URL (override with NIKI_BINARY_URL=... or --url <URL>)
BINARY_URL="${NIKI_BINARY_URL:-https://github.com/Nehal987/niki-tools/raw/main/niki_tools}"
EXPECTED_SIZE=87354600
DOWNLOAD_DIR="/sdcard/Download"
DOWNLOAD_COPY="${DOWNLOAD_DIR}/niki_tools"
INSTALL_BIN="${HOME}/niki_tools"
LAUNCHER_LOCAL="${HOME}/tools"
LAUNCHER_GLOBAL="${PREFIX:-/data/data/com.termux/files/usr}/bin/tools"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${1:-}" = "--url" ] && [ -n "${2:-}" ]; then
    BINARY_URL="$2"
fi

echo "=============================================="
echo "  niki_tools Termux Auto-Installer (ARM64)"
echo "=============================================="

ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ]; then
    echo "[!] Error: Unsupported architecture '$ARCH' (aarch64 required)."
    exit 1
fi

echo "[1/5] Installing required Termux dependencies..."
pkg update -y
pkg install -y libffi libexpat openssl ca-certificates curl

echo "[2/5] Checking storage access for Downloads folder..."
if [ ! -d "${HOME}/storage" ] && command -v termux-setup-storage >/dev/null 2>&1; then
    termux-setup-storage || true
    sleep 1
fi

echo "[3/5] Installing niki_tools binary..."
if [ -f "${SCRIPT_DIR}/niki_tools" ] && [ "$(wc -c < "${SCRIPT_DIR}/niki_tools")" -eq "${EXPECTED_SIZE}" ]; then
    echo "      Using local repository binary: ${SCRIPT_DIR}/niki_tools"
    cp -f "${SCRIPT_DIR}/niki_tools" "${INSTALL_BIN}.new"
elif [ -f "${DOWNLOAD_COPY}" ] && [ "$(wc -c < "${DOWNLOAD_COPY}")" -eq "${EXPECTED_SIZE}" ]; then
    echo "      Found binary in Downloads: ${DOWNLOAD_COPY}"
    cp -f "${DOWNLOAD_COPY}" "${INSTALL_BIN}.new"
else
    if [ -z "${BINARY_URL}" ]; then
        echo "[!] No local binary found and BINARY_URL is empty."
        echo "    Either:"
        echo "      1) Set NIKI_BINARY_URL=https://github.com/Nehal987/niki-tools/raw/main/niki_tools bash install.sh"
        echo "      2) Or place niki_tools inside /sdcard/Download/niki_tools and re-run."
        exit 1
    fi
    echo "      Downloading niki_tools from GitHub..."
    curl -fL --progress-bar "${BINARY_URL}" -o "${INSTALL_BIN}.new"
fi

chmod 755 "${INSTALL_BIN}.new"
mv -f "${INSTALL_BIN}.new" "${INSTALL_BIN}"
echo "      Executable installed: ${INSTALL_BIN}"

# Keep a copy in /sdcard/Download/niki_tools as requested
if [ -d "${DOWNLOAD_DIR}" ] && [ -w "${DOWNLOAD_DIR}" ]; then
    if [ ! -f "${DOWNLOAD_COPY}" ] || [ "$(wc -c < "${DOWNLOAD_COPY}")" -ne "${EXPECTED_SIZE}" ]; then
        cp -f "${INSTALL_BIN}" "${DOWNLOAD_COPY}"
        echo "      Copied to Downloads:  ${DOWNLOAD_COPY}"
    fi
fi

echo "[4/5] Creating ./tools launcher..."
cat << 'EOF' > "${LAUNCHER_LOCAL}"
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BIN="${HOME}/niki_tools"
DOWNLOAD_COPY="/sdcard/Download/niki_tools"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
export PREFIX
export LD_LIBRARY_PATH="${PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export TERM="${TERM:-xterm-256color}"

# Auto-recover ~/niki_tools from /sdcard/Download/niki_tools if missing
if [ ! -x "${BIN}" ] && [ -f "${DOWNLOAD_COPY}" ]; then
    cp -f "${DOWNLOAD_COPY}" "${BIN}.new"
    chmod 755 "${BIN}.new"
    mv -f "${BIN}.new" "${BIN}"
fi

CMD="${1:-start}"
case "${CMD}" in
    start)
        exec "${BIN}"
        ;;
    proxy)
        PROXY_ADDR="${2:-127.0.0.1:9000}"
        export HTTP_PROXY="http://${PROXY_ADDR}"
        export HTTPS_PROXY="http://${PROXY_ADDR}"
        export ALL_PROXY="http://${PROXY_ADDR}"
        echo "[*] Launching with MITM proxy: ${PROXY_ADDR}"
        exec "${BIN}"
        ;;
    status)
        echo "Arch:          $(uname -m)"
        echo "Executable:    $(ls -lh "${BIN}" 2>/dev/null || echo 'MISSING')"
        echo "Downloads:     $(ls -lh "${DOWNLOAD_COPY}" 2>/dev/null || echo 'not accessible')"
        echo "libffi.so:     $(ls "${PREFIX}/lib/libffi.so"* 2>/dev/null | head -n1 || echo 'MISSING')"
        echo "libexpat.so:   $(ls "${PREFIX}/lib/libexpat.so"* 2>/dev/null | head -n1 || echo 'MISSING')"
        ;;
    *)
        echo "Usage:"
        echo "  ./tools start                 # Launch normally (Reqable VPN mode ready)"
        echo "  ./tools proxy 127.0.0.1:9000  # Launch with explicit MITM proxy"
        echo "  ./tools status                # Verify binary and Termux libraries"
        exit 1
        ;;
esac
EOF

chmod 755 "${LAUNCHER_LOCAL}"
cp -f "${LAUNCHER_LOCAL}" "${LAUNCHER_GLOBAL}" 2>/dev/null || true
chmod 755 "${LAUNCHER_GLOBAL}" 2>/dev/null || true
cp -f "${LAUNCHER_LOCAL}" "${DOWNLOAD_DIR}/tools" 2>/dev/null || true

echo "[5/5] Setup complete!"
echo "=============================================="
echo "  Start now:  ./tools start"
echo "  Global cmd: tools start"
echo "  Reqable:    Enable Reqable VPN capture and run ./tools start"
echo "              (or ./tools proxy 127.0.0.1:9000 for proxy mode)"
echo "=============================================="
