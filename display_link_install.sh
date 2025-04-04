#!/bin/bash

set -e

echo "🔧 Eliminando instalación anterior de DisplayLink..."
sudo pkill DisplayLinkManager || true
sudo systemctl stop displaylink-driver || true
sudo rm -rf /opt/displaylink
sudo rm -f /etc/udev/rules.d/99-displaylink.rules
sudo rm -f /lib/udev/rules.d/99-displaylink.rules
sudo rm -f /usr/lib/systemd/system/displaylink-driver.service
sudo rm -rf /var/lib/dkms/evdi
sudo rm -rf /usr/src/evdi*
sudo rm -f /lib/modules/$(uname -r)/updates/dkms/evdi.ko
sudo rm -f /lib/modules/$(uname -r)/kernel/drivers/gpu/drm/evdi.ko
sudo depmod -a

echo "🔄 Removiendo evdi de DKMS (si existe)..."
sudo dkms remove -m evdi -v 1.12.0 --all || true

echo "📦 Instalando dependencias..."
sudo apt update
sudo apt install -y dkms build-essential linux-headers-$(uname -r) git libdrm-dev

echo "📥 Clonando evdi desde GitHub..."
rm -rf ~/evdi
git clone https://github.com/DisplayLink/evdi.git ~/evdi
cd ~/evdi

echo "✂️ Quitando -Werror del Makefile..."
sed -i 's/-Werror//g' module/Makefile

echo "📁 Preparando DKMS..."
sudo mkdir -p /usr/src/evdi-1.12.0
sudo cp -r module/* /usr/src/evdi-1.12.0/

echo "📦 Instalando evdi con DKMS..."
sudo dkms add -m evdi -v 1.12.0
sudo dkms build -m evdi -v 1.12.0
sudo dkms install -m evdi -v 1.12.0

echo "🚀 Ejecutando instalador DisplayLink 5.6.1..."
cd ~/Downloads
chmod +x displaylink-driver-5.6.1-59.184.run
sudo ./displaylink-driver-5.6.1-59.184.run

echo "🔁 Reiniciando servicio displaylink-driver..."
sudo systemctl daemon-reexec
sudo systemctl restart displaylink-driver

echo "✅ Estado actual del módulo:"
ls /sys/class/drm/
xrandr --listproviders
