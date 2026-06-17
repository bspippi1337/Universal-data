#!/data/data/com.termux/files/usr/bin/sh

SSID='ssid'
PASS='password'
LOG="/sdcard/force_ssid_wifi.log"

say(){ echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

cleanup(){
  say "Stopper daemon. Ingen permanent tvang lenger."
  exit 0
}

trap cleanup INT TERM EXIT

say "Starter midlertidig Wi-Fi daemon for: $SSID"

while true; do
  CUR="$(su -c "dumpsys wifi | grep -m1 -E 'mWifiInfo|SSID:'" 2>/dev/null | grep -o 'SSID: [^,]*' | head -1 | sed 's/SSID: //; s/\"//g')"

  if [ "$CUR" != "$SSID" ]; then
    say "Ikke på $SSID nå: '$CUR'. Kobler til."
    su -c "svc wifi enable" >/dev/null 2>&1
    sleep 2

    su -c "cmd wifi connect-network '$SSID' wpa2 '$PASS'" >>"$LOG" 2>&1 || \
    su -c "cmd wifi connect-network \"$SSID\" wpa2 \"$PASS\"" >>"$LOG" 2>&1 || \
    su -c "am start -a android.settings.WIFI_SETTINGS" >/dev/null 2>&1
  else
    say "OK: koblet til $SSID"
  fi

  sleep 10
done
