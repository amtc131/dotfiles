#!/bin/bash

set -e

echo "🔧 Instalando dependencias..."
sudo apt update
sudo apt install -y dkms build-essential linux-headers-$(uname -r) git libdrm-dev

echo "📥 Clonando evdi desde GitHub..."
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

echo "🚀 Ejecutando instalador DisplayLink..."
cd /home/alex/Downloads/ 
chmod +x displaylink-driver-5.6.1-59.184.run
sudo ./displaylink-driver-5.6.1-59.184.run

echo "🔁 Reiniciando servicio displaylink-driver..."
sudo systemctl restart displaylink-driver
sleep 3

echo "✅ Verificando módulos y salidas disponibles..."
ls /sys/class/drm/
xrandr --listproviders

