#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

IP=""
for iface in en0 en1 en2; do
  candidate="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
  if [[ -n "$candidate" ]]; then
    IP="$candidate"
    break
  fi
done

if [[ -z "$IP" ]]; then
  echo "LAN IP bulunamadı. Wi‑Fi bağlı mı kontrol edin."
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo ".env bulunamadı: $ENV_FILE"
  exit 1
fi

tmp="$(mktemp)"
awk -v ip="$IP" '
  /^API_LAN_HOST=/ { print "API_LAN_HOST=" ip; next }
  /^API_BASE_URL=/ { print "API_BASE_URL=http://" ip ":3011"; next }
  { print }
' "$ENV_FILE" > "$tmp"
mv "$tmp" "$ENV_FILE"

echo "Güncellendi: API_LAN_HOST=$IP"
echo "API_BASE_URL=http://$IP:3011"
echo "Flutter için uygulamayı tam yeniden başlatın (hot reload .env okumaz)."
