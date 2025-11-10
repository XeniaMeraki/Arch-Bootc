#       !`              @                            ☆ﾟ.*･｡ﾟXeniaOS ﾟ｡･*.ﾟ☆
#      @```b        @@@@@                         Arch/CachyOS Bootc | Niri
#     @`````@     @/@@@@                       Noctalia | DMS | Gaming On Linux
#    @@``'))))))))))C@@                       Starship | Ptyxis | Dolphin on Niri
#   @@@){)))))())))))))                              ☆ﾟ.Flatpaks | FOSS.ﾟ☆
#    @r))))@oooo)))))h)))[                                 
#    rr)))joooooo(xooooo@)
# rrrxr))r/l;,,,z@{,,,,,@@                         One containerfile to rule them all!
#   rr  )        v  @;@rx                             Trans rights are human rights!
#     rrr)    \__^__/   ji                                
#      rj].           . r
#      [[]]11111111111111111]                                   Credits
#     ][[[]]][11111111111111111<                  Arch | Bootc | Bazzite | Ublue | Zirconium 
#     ][[[[[]]]]]]]]]]]]]]-111111[                  Xenia Meraki the transfem package fox
#     ]-[[[[[[;]]]]]]]]]]]]]]]]   1                 Docker | Podman | Fedora | Proton | Wine 
#     ]][[[[[[[[[[[]]]]]]]]]]]]]                    @tulilirockz @kylegospo @valerie-tar-gz
#     1]][[[[[[[[[[[[[[<]]]]]]]]]                    Artists Jasper Valery | Delphic Melody
#      11]]][[[[[[[[[[[[[[[]]]]]]]                           Chimmie Firefly
#       111]]]]'[[[[[[[[[[[[[[]]]]
#         111-]]]]][[[[[[[[[[[[[]]
#           11111]]]]]_[[[[[[[[[[]
#               11111]]]i[[[[[[[[
#                  1111]]+[[[[[[^
#                    11 ]][[[[[[
#                    11 +][[[[
#                    1   ][[
#                       `            Credit art: Cathodegaytube for original art, @catumin for ascii-ification

FROM scratch AS ctx

COPY build_scripts /build
COPY system_files /files

FROM docker.io/cachyos/cachyos:latest

ENV DEV_DEPS="base-devel git rust"

ENV DRACUT_NO_XATTR=1

# Section 1 - Package Installs
# Section 2 - Set up bootc dracut
# Section 3 - AUR Builder
# Section 4 - Spawn config files
# Section 5 - Final Bootc Setup
########################################################################################################################################
# Section 1 - Package Installs #########################################################################################################
########################################################################################################################################

      RUN pacman -Syyuu --noconfirm \
# Base packages
      base dracut linux linux-firmware ostree systemd btrfs-progs e2fsprogs xfsprogs binutils dosfstools skopeo dbus dbus-glib glib2 shadow \
\
# Media/Install utilities
      RUN pacman -S --noconfirm librsvg libglvnd qt6-multimedia-ffmpeg plymouth flatpak acpid aha clinfo ddcutil dmidecode mesa-utils ntfs-3g nvme-cli vulkan-tools wayland-utils \
\
# Fonts
      RUN pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji && \
\
# CLI Utilities
      RUN pacman -S --noconfirm bash-completion bat busybox duf hyfetch fd gping grml-zsh-config htop jq less lsof mcfly nano nvtop openssh powertop \
      procs ripgrep tldr trash-cli tree usbutils vim wget wl-clipboard ydotool zsh zsh-completions yay unzip \
\
# Drivers
      RUN pacman -S --noconfirm amd-ucode intel-ucode edk2-shell efibootmgr shim mesa libva-intel-driver libva-mesa-driver \
      vpl-gpu-rt vulkan-icd-loader vulkan-intel vulkan-radeon apparmor \
\
# Network / VPN / SMB
      RUN pacman -S --noconfirm dnsmasq freerdp2 iproute2 iwd libmtp networkmanager-l2tp networkmanager-openconnect networkmanager-openvpn networkmanager-pptp \
      networkmanager-strongswan networkmanager-vpnc nfs-utils nss-mdns samba smbclient ufw \
\
# Accessibility
      RUN pacman -S --noconfirm espeak-ng orca \
\
# Pipewire
      RUN pacman -S --noconfirm pipewire pipewire-pulse pipewire-zeroconf pipewire-ffado pipewire-libcamera sof-firmware wireplumber pipewire-jack \
\
# Printer
      RUN pacman -S --noconfirm cups cups-browsed gutenprint ipp-usb hplip splix system-config-printer \
\
# Desktop Environment needs
      RUN pacman -S --noconfirm greetd udiskie polkit-kde-agent xwayland-satellite greetd-tuigreet xdg-desktop-portal-kde xdg-desktop-portal xdg-user-dirs dolphin \
      ffmpegthumbs filelight kdegraphics-thumbnailers kdenetwork-filesharing kio-admin kompare purpose chezmoi flatpak \
\
      ${DEV_DEPS} && \
  pacman -S --clean --noconfirm && \
  rm -rf /var/cache/pacman/pkg/*

# Add Maple Mono font
RUN mkdir -p "/usr/share/fonts/Maple Mono" \
      && curl -fSsLo "/tmp/maple.zip" "$(curl "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | jq '.assets[] | select(.name == "MapleMono-Variable.zip") | .browser_download_url' -rc)" \
      && unzip "/tmp/maple.zip" -d "/usr/share/fonts/Maple Mono"

########################################################################################################################################
# Section 2 - Set up bootc dracut ######################################################################################################
########################################################################################################################################

# Workaround due to dracut version bump, please remove eventually
# FIXME: remove
RUN echo -e "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /etc/dracut.conf.d/fix-bootc.conf

RUN --mount=type=tmpfs,dst=/tmp --mount=type=tmpfs,dst=/root \
    pacman -S --noconfirm base-devel git rust && \
    git clone https://github.com/bootc-dev/bootc.git /tmp/bootc && \
    make -C /tmp/bootc bin install-all install-initramfs-dracut && \
    sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --add ostree --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"' && \
    pacman -S --clean --noconfirm

########################################################################################################################################
# Section 3 - AUR Builder ##############################################################################################################
########################################################################################################################################

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
      aur/niri-git \
      aur/noctalia-shell-git \
      aur/matugen-bin \
      aur/input-remapper-bin \
      aur/vesktop-bin \
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

########################################################################################################################################
# Section 4 - Spawn config files #######################################################################################################
########################################################################################################################################

# Add config for dolphin to Niri and switch away from GTK/Nautilus, use Dolphin for file chooser.
      RUN echo $'[repo] \n\
[preferred] \n\
default=kde;gtk;gnome; \n\
org.freedesktop.impl.portal.Access=kde; \n\
org.freedesktop.impl.portal.Notification=kde; \n\
org.freedesktop.impl.portal.Secret=gnome-keyring; \n\
org.freedesktop.impl.portal.FileChooser=kde;' > /usr/share/xdg-desktop-portal/niri-portals.conf

# Use Chezmoi to set up visual assets, avatars, and wallpapers
      RUN rm -rf /usr/share/xeniaos/zdots && \
      git clone https://github.com/XeniaMeraki/XeniaOS-HRT /usr/share/xeniaos/zdots

# Flatpak repo add
      RUN mkdir -p /etc/flatpak/remotes.d/ && \
      curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# Noctalia Service add
      RUN echo $'[repo] \n\
[Unit] \n\
Description=Noctalia Shell Service \n\
PartOf=graphical-session.target \n\
After=graphical-session.target \n\
 \n\
[Service] \n\
ExecStart=qs -p /etc/xdg/quickshell/noctalia-shell \n\
Restart=on-failure \n\
RestartSec=1 \n\
\n\
[Install] \n\
WantedBy=graphical-session.target' > /usr/lib/systemd/user/noctalia.service

# OS Release and Update uwu
      RUN echo $'[repo] \n\
NAME="XeniaOS" \n\
PRETTY_NAME="XeniaOS" \n\
DEFAULT_HOSTNAME="XeniaOS" \n\
HOME_URL="https://github.com/XeniaMeraki/XeniaOS"' > /etc/os-release

# Activate NTSync
      RUN echo $'[repo] \n\
      ntsync' > /etc/modules-load.d/ntsync.conf

# CachyOS bbr3 Config Option
      RUN echo $'[repo] \n\
net.core.default_qdisc=fq \n\
net.ipv4.tcp_congestion_control=bbr' > /etc/sysctl.d/99-bbr3.conf

########################################################################################################################################
# Section 5 - Final Bootc Setup ########################################################################################################
########################################################################################################################################

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/00-theme.sh

RUN pacman -S whois --noconfirm
RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root

RUN bootc container lint
