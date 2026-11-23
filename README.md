# niki_tools (Android Termux ARM64 + Reqable MITM Edition)

Pre-configured AArch64 Termux release with one-paste installation, `./tools start` launcher, and built-in **Reqable / MITM SSL inspection support** (`verify=False` + cert-pinning bypass across `requests`, `curl_cffi`, `httpx`, and `ssl`).

---

## 1. Termux Quick Start (Paste in Terminal)

### Option A — One-Paste Install (Curl Auto-Setup)

```bash
cd ~ && pkg update -y && pkg install -y curl && \
curl -fsSL https://raw.githubusercontent.com/Nehal987/niki-tools/main/install.sh -o install.sh && \
bash install.sh && \
./tools start
```

### Option B — One-Paste Install via Git Clone

```bash
cd ~ && pkg update -y && pkg install -y git && \
git clone https://github.com/Nehal987/niki-tools.git niki-tools && \
bash ~/niki-tools/install.sh && \
./tools start
```

### Option C — Local `/sdcard/Download/niki_tools` Copy
If `niki_tools` is already in your phone's `Download` folder:

```bash
cd ~ && termux-setup-storage && bash install.sh && ./tools start
```

---

## 2. Launcher Commands (`./tools`)

After installation, `niki_tools` is copied to `/sdcard/Download/niki_tools` (backup/visible in Downloads) and installed as an executable at `~/niki_tools` (because Android mounts `/sdcard/Download` as `noexec`).

```bash
./tools start                 # Start the tool normally (works with Reqable VPN capture)
./tools proxy 127.0.0.1:9000  # Start with explicit HTTP/HTTPS MITM proxy
./tools status                # Verify binary and Termux libraries (libffi, libexpat)
```

---

## 3. Capturing Live API Traffic with Reqable (Android)

SSL certificate verification (`verify=False`) and custom TLS pinning (`_cq98g69x`) are **already disabled** inside this build for all HTTP libraries (`requests`, `urllib3`, `curl_cffi`/BoringSSL, `httpx`, and `ssl`), and `trust_env=True` + proxy environment variables are preserved.

1. Open **Reqable** on your Android phone and start capture (**VPN mode**).
2. Make sure **Termux** is included in Reqable's target apps (or capture All Apps).
3. Open Termux and run:
   ```bash
   ./tools start
   ```
4. If using Reqable in **Proxy mode** instead of VPN mode, run:
   ```bash
   ./tools proxy 127.0.0.1:9000
   ```
5. Select any tool option in the menu — all outgoing HTTPS API calls (`graph.facebook.com`, `b-graph.facebook.com`, `i.instagram.com`, etc.) will appear decrypted in Reqable without SSL errors or root CA installation required.

---

## 4. Repository Info (`Nehal987/niki-tools`)

Hosted at `https://github.com/Nehal987/niki-tools` (default branch `main`, containing `niki_tools` `87,354,600 B`, `install.sh`, `tools`, `README.md`, and `ANDROID_SETUP.md`).

To push updates from `hooked/`:

```bash
cd hooked
git add -A
git commit -m "Update release"
git push origin main
```
