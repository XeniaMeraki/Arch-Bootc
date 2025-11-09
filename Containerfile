FROM scratch AS ctx

COPY build_scripts /build
COPY system_files /files

FROM docker.io/cachyos/cachyos:latest AS builder

ENV DEV_DEPS="base-devel git rust"

ENV DRACUT_NO_XATTR=1

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
    printf  "[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n" | \
    tee "/usr/lib/ostree/prepare-root.conf"

RUN pacman -S --noconfirm greetd udiskie polkit-kde-agent xwayland-satellite greetd-tuigreet

# Install AUR packages
USER build
WORKDIR /home/build
RUN --mount=type=tmpfs,dst=/tmp \
    git clone https://aur.archlinux.org/paru-bin.git --single-branch /tmp/paru && \
    cd /tmp/paru && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -drf paru-bin

RUN paru -S \
        aur/steam-devices-git \
        aur/uxplay \
        aur/niri-git \
        aur/noctalia-shell-git \
        aur/matugen-bin \
        aur/input-remapper-bin \
        --noconfirm

USER root
WORKDIR /

RUN userdel -r build && \
    rm -drf /home/build && \
    sed -i '/build ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    sed -i '/root ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    rm -rf /home/build && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/*

# END ##########################################################################################################################################

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/00-theme.sh

RUN pacman -S whois --noconfirm
RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root

RUN bootc container lint
