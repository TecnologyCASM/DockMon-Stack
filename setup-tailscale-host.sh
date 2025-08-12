#!/bin/bash
set -e

echo "🚀 Iniciando despliegue de DockMon-Stack..."

# 1. Levantar los contenedores
docker compose up -d
echo "✅ Contenedores levantados."

# 2. Instalar Tailscale si no está presente
if ! command -v tailscale &> /dev/null; then
  echo "📦 Instalando Tailscale en el host..."
  curl -fsSL https://tailscale.com/install.sh | sh
else
  echo "✅ Tailscale ya está instalado."
fi

# 3. Cargar variables desde .env
source "$(dirname "$0")/.env"

# 4. Activar IP forwarding
echo "🔧 Activando IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# 5. Optimizar red con ethtool
echo "⚙️ Aplicando optimización UDP GRO..."
NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
sudo ethtool -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off

# 6. Ejecutar tailscale up con flags
echo "🔐 Registrando homelab en Tailscale..."
sudo tailscale up \
  --authkey="${TS_AUTHKEY}" \
  --advertise-routes=192.168.1.0/24 \
  --advertise-exit-node

echo "🎉 Tailscale instalado y configurado correctamente en el host."

