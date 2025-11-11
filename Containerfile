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

FROM docker.io/cachyos/cachyos:latest

ENV DEV_DEPS="base-devel git rust"

ENV DRACUT_NO_XATTR=1

# Section 1 - Package Installs
# Section 2 - Set up bootc dracut
# Section 3 - Chaotic AUR
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
      librsvg libglvnd qt6-multimedia-ffmpeg plymouth flatpak acpid aha clinfo ddcutil dmidecode mesa-utils ntfs-3g nvme-cli vulkan-tools wayland-utils \
\
# Fonts
      noto-fonts noto-fonts-cjk noto-fonts-emoji \
\
# CLI Utilities
      bash-completion bat busybox duf hyfetch fd gping grml-zsh-config htop jq less lsof mcfly nano nvtop openssh powertop \
      procs ripgrep tldr trash-cli tree usbutils vim wget wl-clipboard ydotool zsh zsh-completions yay unzip \
\
# Drivers
      amd-ucode intel-ucode edk2-shell efibootmgr shim mesa libva-intel-driver libva-mesa-driver \
      vpl-gpu-rt vulkan-icd-loader vulkan-intel vulkan-radeon apparmor \
\
# Network / VPN / SMB
      dnsmasq freerdp2 iproute2 iwd libmtp networkmanager-l2tp networkmanager-openconnect networkmanager-openvpn networkmanager-pptp \
      networkmanager-strongswan networkmanager-vpnc nfs-utils nss-mdns samba smbclient ufw \
\
# Accessibility
      espeak-ng orca \
\
# Pipewire
      pipewire pipewire-pulse pipewire-zeroconf pipewire-ffado pipewire-libcamera sof-firmware wireplumber pipewire-jack \
\
# Printer
      cups cups-browsed gutenprint ipp-usb hplip splix system-config-printer \
\
# Desktop Environment needs
      greetd udiskie polkit-kde-agent xwayland-satellite greetd-tuigreet xdg-desktop-portal-kde xdg-desktop-portal xdg-user-dirs dolphin \
      ffmpegthumbs filelight kdegraphics-thumbnailers kdenetwork-filesharing kio-admin kompare purpose chezmoi flatpak matugen \
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
RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /etc/dracut.conf.d/fix-bootc.conf

RUN --mount=type=tmpfs,dst=/tmp --mount=type=tmpfs,dst=/root \
    pacman -S --noconfirm base-devel git rust && \
    git clone https://github.com/bootc-dev/bootc.git /tmp/bootc && \
    make -C /tmp/bootc bin install-all install-initramfs-dracut && \
    sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --add ostree --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"' && \
    pacman -S --clean --noconfirm

########################################################################################################################################
# Section 3 - Chaotic AUR ##############################################################################################################
########################################################################################################################################

RUN pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com

RUN pacman-key --init && pacman-key --lsign-key 3056513887B78AEB

RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm

RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm

RUN echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf

RUN pacman -Sy --noconfirm

RUN pacman -S \
      chaotic-aur/niri-git \
      chaotic-aur/noctalia-shell \
      chaotic-aur/input-remapper-git \
      chaotic-aur/vesktop-git \
        --noconfirm

########################################################################################################################################
# Section 4 - Spawn config files #######################################################################################################
########################################################################################################################################

# Add config for dolphin to Niri and switch away from GTK/Nautilus, use Dolphin for file chooser.
RUN echo -ne '[preferred] \n\
default=kde;gtk;gnome; \n\
org.freedesktop.impl.portal.Access=kde; \n\
org.freedesktop.impl.portal.Notification=kde; \n\
org.freedesktop.impl.portal.Secret=gnome-keyring; \n\
org.freedesktop.impl.portal.FileChooser=kde;' > /usr/share/xdg-desktop-portal/niri-portals.conf

# Use Chezmoi to set up visual assets, avatars, and wallpapers
RUN mkdir -p /usr/share/xeniaos/ && \
      git clone https://github.com/XeniaMeraki/XeniaOS-HRT /usr/share/xeniaos/zdots

RUN mkdir -p /usr/share/xeniaos/ && \
      git clone https://github.com/XeniaMeraki/XeniaOS-G-Euphoria /usr/share/xeniaos/wallpapers

# Flatpak repo add
RUN mkdir -p /etc/flatpak/remotes.d/ && \
      curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# Noctalia Service add
RUN echo -ne '[Unit] \n\
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
RUN echo -ne 'NAME="XeniaOS" \n\
PRETTY_NAME="XeniaOS" \n\
DEFAULT_HOSTNAME="XeniaOS" \n\
HOME_URL="https://github.com/XeniaMeraki/XeniaOS"' > /etc/os-release

# Activate NTSync
RUN echo 'ntsync' > /etc/modules-load.d/ntsync.conf

# CachyOS bbr3 Config Option
RUN echo -ne 'net.core.default_qdisc=fq \n\
net.ipv4.tcp_congestion_control=bbr' > /etc/sysctl.d/99-bbr3.conf

#Starship setup
RUN echo 'eval "$(starship init bash)"' >> /etc/bash.bashrc

# Automounter Systemd Service
RUN echo -ne '[Unit] \n\
Description=Udiskie automount \n\
PartOf=graphical-session.target \n\
After=graphical-session.target \n\
 \n\
[Service] \n\
ExecStart=udiskie \n\
Restart=on-failure \n\
RestartSec=1 \n\
\n\
[Install] \n\
WantedBy=graphical-session.target' > /usr/lib/systemd/user/udiskie.service

# XWayland Satellite Systemd Service
RUN echo -ne '[Unit] \n\
Description=Xwayland satellite \n\
PartOf=graphical-session.target \n\
After=graphical-session.target \n\
 \n\
[Service] \n\
ExecStart=xwayland-sattelite \n\
Restart=on-failure \n\
RestartSec=1 \n\
\n\
[Install] \n\
WantedBy=graphical-session.target' > /usr/lib/systemd/user/xwayland-satellite.service

# Starts with Niri Session - Services for User Interaction
RUN sed -i "s/\[Unit\]/\[Unit\]\nWants=plasma-polkit-agent.service/" "/usr/lib/systemd/user/niri.service"
RUN sed -i "s/\[Unit\]/\[Unit\]\nWants=udiskie.service/" "/usr/lib/systemd/user/niri.service"
RUN sed -i "s/\[Unit\]/\[Unit\]\nWants=xwayland-satellite.service/" "/usr/lib/systemd/user/niri.service"
RUN sed -i "s/\[Unit\]/\[Unit\]\nWants=noctalia.service/" "/usr/lib/systemd/user/niri.service"
RUN systemctl enable greetd

RUN echo -ne '[Unit]\n\
Description=Initializes Chezmoi if directory is missing\n\
ConditionPathExists=!%h/.config/xeniaos/chezmoi\n\
\n\
[Service]\n\
ExecStart=mkdir -p %h/.config/xeniaos/chezmoi\n\
ExecStart=touch %h/.config/xeniaos/chezmoi/chezmoi.toml\n\
ExecStart=chezmoi apply -S /usr/share/xeniaos/zdots --config %h/.config/xeniaos/chezmoi/chezmoi.toml\n\
Type=oneshot\n\
\n\
[Install]\n\
WantedBy=default.target' >> /usr/lib/systemd/user/chezmoi-init.service

RUN echo -ne "[Unit]\n\
Description=Chezmoi Update\n\
\n\
[Service]\n\
ExecStart=mkdir -p %h/.config/xeniaos/chezmoi\n\
ExecStart=touch %h/.config/xeniaos/chezmoi/chezmoi.toml\n\
ExecStart=sh -c 'yes s | chezmoi apply --no-tty --keep-going -S /usr/share/xeniaos/zdots --verbose --config %h/.config/xeniaos/chezmoi/chezmoi.toml'\n\
Type=oneshot" >> /usr/lib/systemd/user/chezmoi-update.service

RUN mkdir -p /usr/lib/systemd/system-preset /usr/lib/systemd/system

RUN echo -ne '[Unit]\n\
Description=Fix groups\n\
Wants=local-fs.target\n\
After=local-fs.target\n\
ConditionPathExists=!/etc/.xeniaos-fix-group-done\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/bin/cp /usr/etc/group /etc/group\n\
ExecStart=/usr/bin/cp /usr/etc/group- /etc/group-\n\
ExecStart=/usr/bin/touch /etc/.xeniaos-fix-group-done\n\
[Install]\n\
WantedBy=default.target multi-user.target' > /usr/lib/systemd/system/xeniaos-group-fix.service

RUN echo "enable xeniaos-group-fix.service" > /usr/lib/systemd/system-preset/01-xeniaos-group-fix.preset
RUN systemctl enable xeniaos-group-fix.service
RUN echo -ne '[Unit]\n\
Description=Timer for Chezmoi Update\n\
# This service will only execute for a user with an existing chezmoi directory\n\
ConditionPathExists=%h/.config/xeniaos/chezmoi\n\
\n\
[Timer]\n\
OnBootSec=5m\n\
OnUnitInactiveSec=1d\n\
\n\
[Install]\n\
WantedBy=timers.target' >> /usr/lib/systemd/user/chezmoi-update.timer

# Greetd Setup - Login Manager
RUN echo 'u     greetd -     "greetd daemon" /var/lib/greetd' > /usr/lib/sysusers.d/greetd.conf
RUN echo 'Z  /var/lib/greetd -    greetd greetd -   -' > /usr/lib/tmpfiles.d/greetd.conf

# Login tui setup
RUN echo -ne '[terminal]\n\
vt = 1\n\
\n\
[default_session]\n\
command = "tuigreet --time --user-menu --remember --remember-session --asterisks --power-no-setsid --width 140 --theme border=magenta;text=magenta;prompt=lightmagenta;time=magenta;action=lightmagenta;button=magenta;container=gray;input=magenta --cmd niri-session"\n\
user = "greetd"' > /etc/greetd/config.toml

########################################################################################################################################
# Section 5 - Final Bootc Setup ########################################################################################################
########################################################################################################################################

# Necessary for general behavior expected by image-based systems
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv && \
    mkdir -p /var /sysroot /boot /usr/lib/ostree && \
    ln -s var/opt /opt && \
    ln -s var/roothome /root && \
    ln -s var/home /home && \
    ln -s sysroot/ostree /ostree && \
    echo "$(for dir in opt usrlocal home srv mnt ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a /usr/lib/tmpfiles.d/bootc-base-dirs.conf && \
    echo "d /var/roothome 0700 root root -" | tee -a /usr/lib/tmpfiles.d/bootc-base-dirs.conf && \
    echo "d /run/media 0755 root root -" | tee -a /usr/lib/tmpfiles.d/bootc-base-dirs.conf && \
    printf "[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n" | tee "/usr/lib/ostree/prepare-root.conf"

#Final user setup and lint

RUN pacman -S whois --noconfirm
RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root

RUN bootc container lint
