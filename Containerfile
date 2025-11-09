FROM docker.io/cachyos/cachyos:latest AS builder

ENV DEV_DEPS="base-devel git rust"

ENV DRACUT_NO_XATTR=1

RUN pacman -Sy --noconfirm
RUN pacman -Syu --noconfirm
RUN pacman -S cmake --noconfirm
RUN pacman -S git --noconfirm
RUN pacman -S base-devel --noconfirm

RUN pacman -Syyuu --noconfirm \
#Base packages
      base dracut linux linux-firmware ostree systemd btrfs-progs e2fsprogs xfsprogs binutils dosfstools skopeo dbus dbus-glib glib2 shadow \
\
#Media/Install utilities
       librsvg libglvnd qt6-multimedia-ffmpeg plymouth flatpak acpid aha clinfo ddcutil dmidecode mesa-utils ntfs-3g nvme-cli vulkan-tools wayland-utils \
\
#Fonts
      noto-fonts noto-fonts-cjk noto-fonts-emoji \
\
#CLI Utilities
      bash-completion bat busybox duf hyfetch fd gping grml-zsh-config htop jq less lsof mcfly nano vim nvtop openssh powertop \
      procs ripgrep tldr trash-cli tree usbutils wget wl-clipboard ydotool zsh zsh-completions yay fish yad paru \
\
#Drivers
      amd-ucode intel-ucode edk2-shell efibootmgr shim mesa libva-intel-driver libva-mesa-driver lib32-libnm lib32-libpulse \
      vpl-gpu-rt vulkan-icd-loader vulkan-intel vulkan-radeon apparmor lib32-vulkan-radeon vulkan-mesa-layers lib32-openal openal \
\
#Network / VPN / SMB
      dnsmasq freerdp2 iproute2 iwd libmtp networkmanager-l2tp networkmanager-openconnect networkmanager-openvpn networkmanager-pptp \
      networkmanager-strongswan networkmanager-vpnc nfs-utils nss-mdns samba smbclient ufw \
\
#Accessibility
      espeak-ng orca \
\  
#Pipewire
      pipewire pipewire-pulse pipewire-zeroconf pipewire-ffado pipewire-libcamera sof-firmware wireplumber pipewire-jack pipewire-alsa \
\
#Printer
      cups cups-browsed gutenprint ipp-usb hplip splix system-config-printer \
\
#Desktop Environment Tools
      xdg-desktop-portal-kde xdg-user-dirs dolphin \
\
      ${DEV_DEPS} && \
  pacman -S --clean --noconfirm && \
  rm -rf /var/cache/pacman/pkg/*

RUN pacman -S \
        steam \
        lutris \
        mangohud \
        lib32-mangohud \
        --noconfirm && \
        wget https://raw.githubusercontent.com/Shringe/LatencyFleX-Installer/main/install.sh -O /usr/bin/latencyflex && \
        sed -i 's@"dxvk.conf"@"/usr/share/latencyflex/dxvk.conf"@g' /usr/bin/latencyflex && \
        chmod +x /usr/bin/latencyflex && \
    pacman -S --clean --clean && \
    rm -rf /var/cache/pacman/pkg/*
        # Steam/Lutris/Wine installed separately so they use the dependencies above and don't try to install their own.


# START ##########################################################################################################################################
# AUR Build and Install Dedicated Section

RUN useradd -m -G wheel -s /bin/bash builder
RUN sed -Ei 's/^#\ (%wheel.*NOPASSWD.*)/\1/' /etc/sudoers
USER builder
WORKDIR /home/builder/
RUN git clone https://aur.archlinux.org/paru.git && cd paru \
  && makepkg -si --noconfirm && cd .. && rm -rf paru

# Install AUR packages
USER builder
WORKDIR /home/builder
RUN paru -S \
        aur/protontricks \
        aur/vkbasalt \
        aur/lib32-vkbasalt \
        aur/obs-vkcapture-git \
        aur/lib32-obs-vkcapture-git \
        aur/lib32-gperftools \
        aur/steamcmd \
        aur/steam-devices-git \
        aur/niri-git \
        aur/dms-shell-git \
        aur/matugen-bin \
        aur/input-remapper-bin \
        --noconfirm

USER root
WORKDIR /

# END ##########################################################################################################################################


# Workaround due to dracut version bump, please remove eventually
# FIXME: remove
RUN echo -e "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /etc/dracut.conf.d/fix-bootc.conf

RUN --mount=type=tmpfs,dst=/tmp --mount=type=tmpfs,dst=/root \
    pacman -S --noconfirm base-devel git rust && \
    git clone https://github.com/bootc-dev/bootc.git /tmp/bootc && \
    make -C /tmp/bootc bin install-all install-initramfs-dracut && \
    sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"' && \
    pacman -S --clean --noconfirm

# Setup a temporary root passwd (changeme) for dev purposes
# RUN pacman -S 
# RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root
RUN rm -rf /boot /home /root /usr/local /srv && \
    mkdir -p /var/{home,roothome,srv} /sysroot /boot && \
    ln -s sysroot/ostree /ostree

# Update useradd default to /var/home instead of /home for User Creation
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd"

# Necessary for `bootc install`
RUN mkdir -p /usr/lib/ostree && \
    printf  "[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n" | \
    tee "/usr/lib/ostree/prepare-root.conf"

RUN bootc container lint
