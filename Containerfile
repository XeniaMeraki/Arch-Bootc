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
      bash-completion bat busybox duf hyfetch fd gping grml-zsh-config htop jq less lsof mcfly nano nvtop openssh powertop \
      procs ripgrep tldr trash-cli tree usbutils vim wget wl-clipboard ydotool zsh zsh-completions yay \
\
#Drivers
      amd-ucode intel-ucode edk2-shell efibootmgr shim mesa libva-intel-driver libva-mesa-driver \
      vpl-gpu-rt vulkan-icd-loader vulkan-intel vulkan-radeon apparmor \
\
#Network / VPN / SMB
      dnsmasq freerdp2 iproute2 iwd libmtp networkmanager-l2tp networkmanager-openconnect networkmanager-openvpn networkmanager-pptp \
      networkmanager-strongswan networkmanager-vpnc nfs-utils nss-mdns samba smbclient ufw \
\
#Accessibility
      espeak-ng orca \
\  
#Pipewire
      pipewire pipewire-pulse pipewire-zeroconf pipewire-ffado pipewire-libcamera sof-firmware wireplumber pipewire-jack \
\
#Printer
      cups cups-browsed gutenprint ipp-usb hplip splix system-config-printer \
\
      ${DEV_DEPS} && \
  pacman -S --clean --noconfirm && \
  rm -rf /var/cache/pacman/pkg/*

# START ##########################################################################################################################################

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


# Create build user
RUN useradd -m --shell=/bin/bash build && usermod -L build && \
    echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

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

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/00-theme.sh

RUN pacman -S whois --noconfirm
RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root

RUN bootc container lint
