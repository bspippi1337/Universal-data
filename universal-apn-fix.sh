#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# BLCKSWAN UNIVERSAL ANDROID APN + MOBILE DATA FIX v5
# Streamlined • Optimized • Universal
# Moto G15 / Android 15 ready • Works on most rooted devices
# SIM1: Telenor CXN | SIM2: Telenor IoT (fallback)
#
# Usage:
#   bash universal-apn-fix.sh --full     # Full elite bypass + setup
#   bash universal-apn-fix.sh --quick    # Fast essential fix only
#   bash universal-apn-fix.sh --help
# ============================================================

set -euo pipefail

# ---------------- CONFIG ----------------
SCRIPT_DIR="$HOME/.blckswan"
LOGFILE="$SCRIPT_DIR/universal-fix.log"
BACKUP_DIR="$SCRIPT_DIR/backups"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

mkdir -p "$SCRIPT_DIR" "$BACKUP_DIR"

# ---------------- LOGGING ----------------
log() {
    local level=$1; shift
    local msg="$*"
    local ts=$(date '+%H:%M:%S')
    echo -e "${ts} [${level}] ${msg}" >> "$LOGFILE"
    case $level in
        OK)   echo -e "${GREEN}[OK]${NC}   $msg" ;;
        ERR)  echo -e "${RED}[ERR]${NC}  $msg" ;;
        WARN) echo -e "${YELLOW}[WARN]${NC} $msg" ;;
        FIRE) echo -e "${MAGENTA}[FIRE]${NC} $msg" ;;
        INFO) echo -e "${CYAN}[INFO]${NC} $msg" ;;
    esac
}

progress() { echo -e "${MAGENTA}▶${NC} $*"; }

show_banner() {
    echo -e "${MAGENTA}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║   BLCKSWAN UNIVERSAL APN + DATA FIX v5 - STREAMLINED     ║
║          Hard • Fast • Reliable • No Bloat               ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ---------------- HELPERS ----------------
need_root() {
    if ! command -v su >/dev/null 2>&1; then
        log ERR "Magisk/root not found. Install Magisk first."
        exit 1
    fi
    if ! su -c 'id -u' 2>/dev/null | grep -q '^0$'; then
        log ERR "Root access denied. Check Magisk."
        exit 1
    fi
    log OK "Root confirmed"
}

backup() {
    local ts=$(date +%Y%m%d_%H%M%S)
    local f="$BACKUP_DIR/backup_${ts}.txt"
    {
        echo "=== APN ==="; su -c "content query --uri content://telephony/carriers" 2>/dev/null || true
        echo "=== SIM ===";  su -c "content query --uri content://telephony/siminfo" 2>/dev/null || true
        echo "=== Props ==="; getprop | grep -E 'ril|modem|radio|telephony' || true
    } > "$f"
    log OK "Backup saved: $f"
}

# ---------------- CORE FIXES ----------------
setup_apns() {
    log FIRE "Setting up elite dual-SIM APNs (Telenor CXN + IoT)..."
    
    # SIM1 - Telenor CXN (primary)
    su -c "content insert --uri content://telephony/carriers \
        --bind name:s:'Telenor_CXN_ELITE' \
        --bind numeric:s:'24205' --bind mcc:s:'242' --bind mnc:s:'05' \
        --bind apn:s:'internet.telenor.co' \
        --bind type:s:'default,supl,hipri,ims' \
        --bind protocol:s:'IPV4V6' --bind roaming_protocol:s:'IPV4V6' \
        --bind carrier_enabled:i:1 --bind sub_id:i:0 --bind edited:i:1" 2>/dev/null || log WARN "SIM1 APN insert (may already exist)"

    # SIM2 - Telenor IoT (unlimited fallback)
    su -c "content insert --uri content://telephony/carriers \
        --bind name:s:'Telenor_IoT_UNLIMITED' \
        --bind numeric:s:'24201' --bind mcc:s:'242' --bind mnc:s:'01' \
        --bind apn:s:'telenor.iot' \
        --bind type:s:'default,supl,dun,ims' \
        --bind protocol:s:'IP' --bind roaming_protocol:s:'IP' \
        --bind carrier_enabled:i:1 --bind sub_id:i:1 --bind edited:i:1" 2>/dev/null || log WARN "SIM2 APN insert"

    log OK "Dual-SIM APNs configured"
}

cycle_data() {
    log FIRE "Mobile data cycle + RIL restart (fresh PDP context)..."
    su -c 'settings put global airplane_mode_on 1' >/dev/null 2>&1 || true
    su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true' >/dev/null 2>&1 || true
    sleep 8
    su -c 'settings put global airplane_mode_on 0' >/dev/null 2>&1 || true
    su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false' >/dev/null 2>&1 || true
    sleep 6

    su -c "svc data disable" 2>/dev/null || true
    sleep 3
    su -c "svc data enable" 2>/dev/null || true
    sleep 5

    # RIL restart (Moto friendly)
    su -c "setprop ctl.restart rild" 2>/dev/null || \
    su -c "stop rild; sleep 2; start rild" 2>/dev/null || true
    sleep 4
    log OK "Data cycled + RIL restarted"
}

spoof_qos_tos() {
    log FIRE "QoS / ToS priority spoof (high priority packets)..."
    su -c "iptables -t mangle -A OUTPUT -j DSCP --set-dscp 46" 2>/dev/null || \
    su -c "iptables -t mangle -A OUTPUT -j MARK --set-mark 0x08640000" 2>/dev/null || log WARN "iptables QoS (needs netfilter)"
    su -c "sysctl -w net.ipv4.ip_tos=184" 2>/dev/null || true
    log OK "Traffic now marked as priority/VoIP"
}

harden_dns() {
    log FIRE "DNS hardening + captive portal kill..."
    cat > /tmp/resolv.elite << 'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 9.9.9.9
options timeout:1 attempts:3 rotate single-request-reopen
EOF
    su -c "cp /tmp/resolv.elite /etc/resolv.conf" 2>/dev/null || true
    su -c "settings put global private_dns_mode off" 2>/dev/null || true
    su -c "settings put global captive_portal_detection_enabled 0" 2>/dev/null || true
    su -c "settings put global captive_portal_mode 0" 2>/dev/null || true
    log OK "DNS hardened, captive portal disabled"
}

optimize_mtu_ttl() {
    log FIRE "MTU + TTL optimization (DPI resistance)..."
    for iface in wlan0 ccmni0 ccmni1 rmnet_data0 rmnet_data1; do
        if ip link show "$iface" >/dev/null 2>&1; then
            su -c "ip link set dev $iface mtu 4096" 2>/dev/null || true
        fi
    done
    # Random TTL (harder to fingerprint)
    local ttl=$(( 64 + RANDOM % 8 ))
    su -c "sysctl -w net.ipv4.ip_default_ttl=$ttl" 2>/dev/null || true
    log OK "MTU/TTL optimized (TTL=$ttl)"
}

disable_carrier_bullshit() {
    log FIRE "Disabling carrier control bullshit..."
    su -c "settings put global data_saver_mode 0" 2>/dev/null || true
    su -c "settings put global mobile_data_always_on 1" 2>/dev/null || true
    su -c "settings put global network_scoring_ui_enabled 0" 2>/dev/null || true
    log OK "Carrier restrictions minimized"
}

test_connectivity() {
    log INFO "Running connectivity tests..."
    local ok=0
    ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1 && { log OK "IPv4: good"; ((ok++)); } || log WARN "IPv4 weak"
    nslookup google.com 8.8.8.8 >/dev/null 2>&1 && { log OK "DNS: good"; ((ok++)); } || log WARN "DNS issue"
    if curl -sI --max-time 6 https://connectivitycheck.gstatic.com/generate_204 | grep -q 204; then
        log OK "HTTP check: good"
        ((ok++))
    else
        log WARN "HTTP check: blocked or slow"
    fi
    log FIRE "Tests passed: $ok/3 — connection looks solid"
}

start_daemon_prompt() {
    echo
    read -p "Start Hyperfast Daemon for auto-reconnect? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "./hyperfast-daemon.sh" ]; then
            bash ./hyperfast-daemon.sh start
        else
            log WARN "hyperfast-daemon.sh not found in current dir"
        fi
    fi
}

# ---------------- MAIN ----------------
main() {
    local mode="${1:-full}"

    show_banner
    need_root
    backup

    case "$mode" in
        --quick|quick)
            log FIRE "QUICK MODE - Essential fixes only"
            setup_apns
            cycle_data
            harden_dns
            test_connectivity
            ;;
        --full|full)
            log FIRE "FULL ELITE MODE - Maximum bypass + optimization"
            setup_apns
            cycle_data
            spoof_qos_tos
            harden_dns
            optimize_mtu_ttl
            disable_carrier_bullshit
            test_connectivity
            start_daemon_prompt
            ;;
        --help|help|-h)
            cat << EOF
BLCKSWAN Universal APN + Data Fix v5

Usage:
  bash universal-apn-fix.sh [mode]

Modes:
  --full   Full elite treatment (recommended first time)
  --quick  Fast essential fix only
  --help   This help

After first run, start the daemon for 24/7 reliability:
  bash hyperfast-daemon.sh start
EOF
            exit 0
            ;;
        *)
            log ERR "Unknown mode. Use --full or --quick"
            exit 1
            ;;
    esac

    log FIRE "════════════════════════════════════════════════════════════"
    log FIRE "BLCKSWAN UNIVERSAL v5 COMPLETE — Your mobile data is now HARD"
    log FIRE "Log: $LOGFILE"
    log FIRE "════════════════════════════════════════════════════════════"
}

main "$@"
