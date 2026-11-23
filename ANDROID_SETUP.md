# Android Termux Setup & Usage Guide for `hooked/niki_tools`

## 1. Overview
`hooked/niki_tools` is a pre-modified, hardened AArch64 ELF binary for Android Termux. All license locks, author telemetry, watchdog threads, and environment scrubbing have been eliminated at the machine-code and Python runtime levels.

### What Was Modified (`OBSERVED & VERIFIED`):
1. **Watchdog & Env Scrubber Disabled (`0x534c5d4`, `0x534ca50`):** Replaced with `ret` and `mov w0, #0; ret`. Termux environment variables (`PYTHONPATH`, proxies) are preserved, and no background thread kills the process.
2. **Mutual Integrity Binding Overridden (`0x9d4200`):** `.init_array[0]` modified to `ret`. Loads without `/proc/self/maps` check or custom loader constraints.
3. **Host SHA-256 Check Updated (`0x534b154`):** Host verification updated to match modified `core.so` hash (`114160ca035f3290d9989f51cb5097263b7ca6c57e4cf41c5cfa980be46e2214`), with final `hooked/niki_tools` SHA-256 `faddb8beb393f5a83fbce0e4cc76398c5c6059477ee6d62ef81842b747ad036c`. Host bootstrap buffer `0x2920..0x326c` preserved 100% pristine.
4. **License & Guard Checks Overridden Offline (`0x51dc54`, `0x550cf4`, `0x56c488`, `0x4a5338`, `0x4a5388`, `0x967bf8`, `0x967bfc`, `0x993100`, `0x993104`):**
   - `_bzw884._h8qw7fst` (`0x51dc54`) uses a full 26-instruction AAPCS64 callee-saved frame calling true PLT entries (`PyUnicode_FromString` @ `0x9d4930`, `PyTuple_New` @ `0x9d4900`) to return `("36500", "2099-12-31")`.
   - `_bzw884._kv8nba6` (`0x550cf4`) returns a 64-character hex token via `0x9d4930` with zero calls to GitHub (`pbxha/cznp`) or `ntp.msn.com`.
   - `_m46jkx` (`0x56c488`), `_d3c34rx` (`0x4e8fb0`), and `_tb9unn8r` (`0x4effe8`) stubbed to return `Py_None`, eliminating `os.kill(os.getpid(), 9)` (`SIGKILL` / exit 137).
   - `Py_mod_exec_niki_tools` token-equality branch (`0x4a5338` -> `nop`) and length branch (`0x4a5388` -> `nop`) neutralized so module init proceeds cleanly into `niki_logo` (`0x50be8c`) and `_q2anc5sa` (`0x967280`).
   - Worker dispatcher (`0x993100`, `0x993104` -> `b #0x993224`) and menu gate (`0x967bf8`, `0x967bfc` -> `b #0x967d14`) `_z35cwp6` exit blocks redirected. Pristine `niki_file` prompt call at `0x9a0c90` (`bl #0x4ce5b4`) preserved.
5. **Heartbeat Thread Disabled (`0x55ec4c`):** Stubbed to return `Py_None`. No periodic network pings.
6. **HTTP Monotonic Expiry & Dealloc-Path Checks Overridden (`0x56e054`, `0x56ece0`, `0x56ece4`, `0x56f948`, `0x56fa08`, `0x56fdbc`, `0x56fdc0`, `0x571344`, `0x5713fc`, `0x57176c`, `0x571770`):** Requests via `requests`, `httpx`, and `curl_cffi` bypass both `_last_gh_ok <= 0.0` (including the `PyFloat(0.0)` deallocation branch) and `> 5500.0s` checks and dispatch directly.
7. **Reqable / MITM SSL Capture Enabled (`0x4e4438`, `0x542918`, `0x56da8c`, `0x593460`, `core.zip` `certifi/core.pyc`):**
   - Custom TLS cert-pinning `_cq98g69x` (`0x4e4438`) stubbed to return `Py_False` (`0x9da6d8`).
   - All 3 `trust_env=False` sites in `core.so` (`0x542918`, `0x56da8c`, `0x593460`) changed to `Py_True` (`0x9da6d0`).
   - `certifi/core.pyc` inside `core.zip` (`31,935,812 B`, deflated `certifi/cacert.pem` + `certifi/core.pyc`, `testzip=None`) disables SSL verification across `ssl`, `urllib3`, `requests` (`HTTPAdapter.cert_verify` & `Session.merge_environment_settings`), `curl_cffi` (`Curl.setopt` & `Curl.perform` zeroing `CURLOPT_SSL_VERIFYPEER`/`HOST`/`STATUS`/`PROXY_SSL_*` and skipping `PINNEDPUBLICKEY`), and `httpx` (`create_ssl_context`, `Client.__init__`, `AsyncClient.__init__`), while preserving initial `HTTP_PROXY`/`HTTPS_PROXY`/`ALL_PROXY` env vars across `core.so` startup scrubbing.
8. **All 6 Vercel Livecheck Callsites Disabled (`0x73076c`, `0x7312cc`, `0x754b48`, `0x75589c`, `0x8f35f8`, `0x90e284`):** Machine-code branches jump over outbound `lovecheck-delta.vercel.app` POST calls. Account data never leaks to author endpoints.
9. **Unreferenced `test` Module `os.system` Disabled (`0x3d5a60`):** Stubbed with `mov x0, xzr; ret`.

---

## 2. Requirements on Android
- **Device:** Android AArch64 (64-bit ARM, Android 7.0+).
- **Environment:** Termux (F-Droid version recommended; Google Play Store Termux is deprecated).
- **Dependencies:** Standard Termux packages (`libandroid-support`, `ca-certificates`). Root is **NOT** required.

---

## 3. Step-by-Step Installation on Android (Termux)

### Step 1: One-Paste Termux Install (GitHub or Downloads)
See [README.md](README.md) for the GitHub one-paste command list, or run locally:
```bash
pkg update -y && pkg install -y libffi libexpat openssl ca-certificates curl
termux-setup-storage
bash install.sh
./tools start
```

### Step 2: Launch Modes (`./tools`)
```bash
./tools start                 # Normal launch (works with Reqable VPN capture)
./tools proxy 127.0.0.1:9000  # Launch with explicit MITM proxy (Reqable Proxy mode)
./tools status                # Check binary, Downloads backup, and native libs
```

---

## 4. Troubleshooting & Verification

| Issue | Cause | Fix |
|---|---|---|
| `Permission denied` | File lacks executable bit | Run `chmod +x niki_tools` |
| `Bad system call` | SELinux blocking execution in `/sdcard` | Copy binary to Termux home `~/` first (`cp /sdcard/... ~/`) |
| `No such file or directory` | 32-bit ARM or wrong architecture | Confirm device is 64-bit ARM via `uname -m` (must show `aarch64`) |
| Network SSL errors | Missing CA bundle | Run `pkg install ca-certificates` |

---

## 5. Offline & Privacy Guarantee
`hooked/niki_tools` does not communicate with author servers:
- **No GitHub checks** to `pbxha/cznp`
- **No NTP queries** to `ntp.msn.com`
- **No data reporting** to `lovecheck-delta.vercel.app`
All Facebook/Meta network traffic flows directly and exclusively between your Android device and official Meta endpoints (`graph.facebook.com`, `b-graph.facebook.com`, `i.instagram.com`).
