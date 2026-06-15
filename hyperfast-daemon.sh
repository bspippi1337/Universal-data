#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# BLCKSWAN HYPERFAST DAEMON v6 - STREAMLINED
# Predictive • Lightweight • Reliable auto-reconnect
# Detects problems early and fixes before you notice
# ============================================================

set -euo pipefail

DAEMON_DIR="$HOME/.blckswan"
PID_FILE="$DAEMON_DIR/hyperfast.pid"
LOG="$DAEMON_DIR/hyperfast.log"
STATE="$DAEMON_DIR/state.json"

mkdir -p "$DAEMON_DIR"

# Config (tweak if needed)
CHECK_INTERVAL_NORMAL=4      # seconds
CHECK_INTERVAL_FAST=1
FAIL_THRESHOLD=2
PING_TARGET="8.8.8.8"
PING_TIMEOUT=2

log() {
    local level=$1; shift
    local msg="$*"
    local ts=$(date '+%H:%M:%S')
    echo -e "${ts} [${level}] ${msg}" >> "$LOG"
    case $level in
        FIRE) echo -e "\033[0;35m[FIRE]\033[0m $msg" ;;
        OK)   echo -e "\033[0;32m[OK]\033[0m   $msg" ;;
        WARN) echo -e "\033[1;33m[WARN]\033[0m $msg" ;;
        ERR)  echo -e "\033[0;31m[ERR]\033[0m  $msg" ;;
    esac
}

is_online() {
    timeout "$PING_TIMEOUT" ping -c 1 -W 1 "$PING_TARGET" >/dev/null 2>&1
}

reconnect() {
    log FIRE "Connection drop detected — initiating fast reconnect"
    local start=$(date +%s)

    # Fastest method first
    su -c "svc data disable" 2>/dev/null || true
    sleep 0.8
    su -c "svc data enable" 2>/dev/null || true
    sleep 2

    # If still down, try SIM switch + cycle
    if ! is_online; then
        log WARN "Primary failed — trying SIM2 failover"
        su -c "cmd phone select-default-sim-subscription 1" 2>/dev/null || true
        sleep 2
        su -c "svc data disable" 2>/dev/null || true
        sleep 0.8
        su -c "svc data enable" 2>/dev/null || true
        sleep 3
    fi

    # Nuclear option: RIL restart
    if ! is_online; then
        log WARN "Still down — hard RIL restart"
        su -c "setprop ctl.restart rild" 2>/dev/null || true
        sleep 5
    fi

    local took=$(( $(date +%s) - start ))
    if is_online; then
        log OK "Reconnected successfully in ${took}s"
    else
        log ERR "Reconnect failed after ${took}s — check SIM / signal"
    fi
}

run_daemon() {
    log FIRE "════════════════════════════════════════════════════════════"
    log FIRE "HYPERFAST DAEMON v6 STARTED (PID $$)"
    log FIRE "Checking every ${CHECK_INTERVAL_NORMAL}s • Fast mode on problems"
    log FIRE "════════════════════════════════════════════════════════════"

    local fails=0
    local last_status=""

    while true; do
        if is_online; then
            if [ "$last_status" != "online" ]; then
                log OK "Connection stable"
                last_status="online"
            fi
            fails=0
            sleep "$CHECK_INTERVAL_NORMAL"
        else
            ((fails++))
            log WARN "Offline detected (failure #$fails)"
            if [ $fails -ge $FAIL_THRESHOLD ]; then
                reconnect
                fails=0
            else
                sleep "$CHECK_INTERVAL_FAST"
            fi
            last_status="offline"
        fi
    done
}

start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Daemon already running (PID: $(cat $PID_FILE))"
        return 1
    fi
    nohup bash -c "$(declare -f run_daemon); run_daemon" >> "$LOG" 2>&1 &
    echo $! > "$PID_FILE"
    echo "✅ Hyperfast daemon started (PID: $!)"
}

stop() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            echo "✅ Daemon stopped"
            return 0
        fi
    fi
    echo "Daemon not running"
    return 1
}

status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "✅ RUNNING (PID: $(cat $PID_FILE))"
        echo "Log: $LOG"
    else
        echo "❌ NOT RUNNING"
    fi
}

case "${1:-start}" in
    start)   start ;;
    stop)    stop ;;
    restart) stop; sleep 1; start ;;
    status)  status ;;
    run)     run_daemon ;;   # foreground for testing
    *) echo "Usage: $0 {start|stop|restart|status|run}"; exit 1 ;;
esac
