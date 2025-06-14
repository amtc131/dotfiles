# Entrá al directorio fuente del kernel si no estás ahí
cd /usr/src/linux

# Activar soporte básico de media
scripts/config --enable CONFIG_MEDIA_SUPPORT
scripts/config --enable CONFIG_MEDIA_CONTROLLER
scripts/config --enable CONFIG_MEDIA_CONTROLLER_REQUEST_API

# Núcleo de Video4Linux (necesario para cámaras)
scripts/config --module CONFIG_VIDEO_DEV

# Videobuf2 - buffers para cámaras/video
scripts/config --module CONFIG_VIDEOBUF2_CORE
scripts/config --module CONFIG_VIDEOBUF2_COMMON

# Soporte para cámaras UVC (USB Video Class)
scripts/config --module CONFIG_USB_VIDEO_CLASS

# Soporte para audio USB
scripts/config --module CONFIG_SND_USB_AUDIO

# Resolver dependencias automáticamente
make olddefconfig

# Compilar el kernel y los módulos (puede tardar)
make -j$(nproc)

# Instalar módulos
make modules_install

# Instalar el nuevo kernel
make install

# instalar grub
grub-mkconfig -o /boot/grub/grub.cfg

cd /boot/

mv vmlinuz vmlinuz-6.12.21-gentoo

reboot
