#!/bin/bash

set -e

echo "[*] Instalando configuración de DisplayLink..."

# Copiar evdi.conf
sudo install -Dm644 modules-load.d/evdi.conf /etc/modules-load.d/evdi.conf

# Copiar script de servicio
sudo install -Dm755 init.d/displaylink /etc/init.d/displaylink

# Agregar a OpenRC
sudo rc-update add displaylink default

echo "[✓] Listo. Ejecutá 'sudo rc-service displaylink start' para probar ahora."
