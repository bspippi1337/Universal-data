# Universal Android APN & Mobile Data Fix 🔥

**Optimized & Streamlined Elite Edition v5** by blckswan1337 / Pippi

Universal, root-powered tools to fix, optimize and bypass common Android mobile data / APN issues. Focused on reliability, speed and real results on devices like Moto G15 (Android 15) but designed to be universal across rooted Android.

## What it does (the real shit)

- Proper dual-SIM APN configuration (Telenor CXN + IoT fallback)
- Aggressive but safe mobile data cycle + RIL/modem restart
- QoS / ToS priority spoofing (make data look like high-priority traffic)
- DNS hardening + captive portal kill
- MTU optimization + fragmentation bypass
- TTL randomization for DPI resistance
- 5G / network slice hints
- **Hyperfast daemon**: predictive monitoring + sub-second auto-reconnect when shit drops

No bloat. No placebo. Just what actually moves the needle for mobile data stability and speed.

## ⚠️ WARNINGS (read this or get fucked)

- **REQUIRES ROOT** (Magisk recommended)
- These scripts do aggressive things. Some techniques may violate your carrier's ToS.
- Quota bypass / identity spoof removed in this optimized version (too risky and often useless).
- Test on your own risk. Backup first.
- Works best on Telenor Norway (CXN / IoT) but APN parts are easy to adapt.
- Not for illegal shit. Don't be that guy.

## Quick Start (Termux + root)

```bash
pkg install curl bc   # bc only needed for old daemon, new one avoids it
git clone https://github.com/bspippi1337/Universal-data.git
cd Universal-data

# Main fix (recommended first run)
bash universal-apn-fix.sh --full

# Or quick mode (faster, essential only)
bash universal-apn-fix.sh --quick

# Start the hyperfast auto-reconnect daemon
bash hyperfast-daemon.sh start

# Check status
bash hyperfast-daemon.sh status
```

## Optimized Files

- `universal-apn-fix.sh` — Main streamlined script (modular, fast, with flags)
- `hyperfast-daemon.sh` — Cleaned predictive reconnection daemon (lighter, more reliable)

## Key Improvements in this Optimized Version

- **Streamlined code**: ~60% less lines, no repetition, better functions
- **Universal design**: Auto-detects device, SIMs, interfaces. Easy to adapt for other carriers
- **Faster execution**: Reduced sleeps, parallel safe operations, smarter checks
- **Robust logging**: Clean colored output + log file
- **Command line flags**: --quick, --full, --apn, --daemon, --help
- **Removed risky bloat**: No more direct modem AT injection (unreliable without proper setup), no quota reset, no IMEI spoof
- **Better daemon**: Fixed CPU-heavy loop, removed unnecessary bc in hot path, smarter predictive logic
- **Safety**: Proper error handling, fallbacks, airplane mode handling improved
- **Blckswan vibe kept**: Still spicy, still 1337, just without the fat

## Recommended Workflow

1. Run `universal-apn-fix.sh --full` once (sets everything up)
2. Start `hyperfast-daemon.sh start` (keeps you online 24/7 with predictive reconnect)
3. If connection drops hard → the daemon fixes it before you notice

## Customization

Edit the APN section in `universal-apn-fix.sh` for your carrier (MCC/MNC/APN).

For other devices: the script auto-detects most things via getprop.

## Stay Spicy. Stay Unstoppable.

Made for the real ones who want their mobile data **hard, fast and reliable**.

blckswan1337 | Sandnes/Ålgård | 2026

If it helped you bypass some throttling or just made your connection solid — star the repo and spread the word.

Now go fuck up that network (legally). 🔥💦
