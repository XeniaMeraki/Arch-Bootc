#       !`              @                            ☆ﾟ.*･｡ﾟXeniaOS ﾟ｡･*.ﾟ☆
#      @```b        @@@@@                         Arch/CachyOS Bootc | Niri
#     @`````@     @/@@@@                         DMS | Gaming On Linux | Bazaar
#    @@``'))))))))))C@@                       Starship | Ptyxis | Dolphin on Niri
#   @@@){)))))())))))))                              ☆ﾟ.Flatpaks | FOSS.ﾟ☆
#    @r))))@oooo)))))h)))[                                 
#    rr)))joooooo(xooooo@)
# rrrxr))r/l;,,,z@{,,,,,@@                         One container file to rule them all!
#   rr  )        v  @;@rx                             Trans rights are human rights!
#     rrr)    \__^__/   ji                                Xenia means helping and supporting each other.
#      rj].           . r
#      [[]]11111111111111111]                                   
#     ][[[]]][11111111111111111<                                 XeniaOS
#     ][[[[[]]]]]]]]]]]]]]-111111[        Xenia Meraki the transfem package fox | @tulilirockz saved the distro
#     ]-[[[[[[;]]]]]]]]]]]]]]]]   1             Artists Jasper Valery | Delphic Melody | Chimmie Firefly
#     ]][[[[[[[[[[[]]]]]]]]]]]]]      
#     1]][[[[[[[[[[[[[[<]]]]]]]]]      
#      11]]][[[[[[[[[[[[[[[]]]]]]]                         
#       111]]]]'[[[[[[[[[[[[[[]]]]
#         111-]]]]][[[[[[[[[[[[[]]  Software that makes this OS possible - Distros for inspiration and whose members helped in some way
#           11111]]]]]_[[[[[[[[[[]                   Arch | Bootc | Aurora | Bazzite | Ublue | Zirconium | Bluefin
#               11111]]]i[[[[[[[[                          Docker | Podman | Fedora | Proton | Wine | Ubuntu
#                  1111]]+[[[[[[^                                @kylegospo @valerie-tar-gz @cyrv6737
#                    11 ]][[[[[[
#                    11 +][[[[
#                    1   ][[
#                       `            Credit art: Cathodegaytube for original art, @catumin for ascii-ification

FROM docker.io/cachyos/cachyos-v3:latest

ENV DEV_DEPS="base-devel git rust"

ENV DRACUT_NO_XATTR=1

# ✩₊˚.⋆☾𓃦☽⋆⁺₊✧ Index
# Section 0 - Pre-setup
# Section 1 - Package Installs
# Section 1.5 - Package List
# Section 2 - Set up bootc dracut
# Section 3 - Chaotic AUR
# Section 4 - Flatpaks preinstalls
# Section 5 - Linux OS Stuffs
# Section 6 - CachyOS Settings
# Section 7 - Niri/Chezmoi/DMS
# Section 8 - Final Bootc Setup

########################################################################################################################################
# Section 0 - Pre-setup | We do some system maintenance tasks + Set up some things for the rest of the containerfile to go smooothly! ##
########################################################################################################################################

# Set it up such that pacman will automatically clean package cache after each install
# So that we don't run out of memory in image generation and don't need to append --clean after everything
# ALSO DO NOT APPEND --CLEAN TO ANYTHING :D
RUN echo -e "[Trigger]\n\
Operation = Install\n\
Operation = Upgrade\n\
Type = Package\n\
Target = *\n\
\n\
[Action]\n\
Description = Cleaning up package cache...\n\
Depends = coreutils\n\
When = PostTransaction\n\
Exec = /usr/bin/rm -rf /var/cache/pacman/pkg" | tee /usr/share/libalpm/hooks/package-cleanup.hook

########################################################################################################################################
# Section 1 - Package Installs | We grab every package we can from official arch repo/set up all non-flatpak apps for user ^^ ##########
########################################################################################################################################

# Initialize the database
RUN pacman -Syu --noconfirm

# Use the Arch mirrorlist that will be best at the moment for both the containerfile and user too! Fox will help!
RUN pacman -S --noconfirm reflector

# Base packages \ Linux Foundation \ Foss is love, foss is life! We split up packages by category for readability, debug ease, and less dependency trouble
RUN pacman -S --noconfirm base dracut linux-cachyos-bore linux-firmware ostree systemd btrfs-progs e2fsprogs xfsprogs binutils dosfstools skopeo dbus dbus-glib glib2 shadow

# Media/Install utilities/Media drivers
RUN pacman -S --noconfirm librsvg libglvnd qt6-multimedia-ffmpeg plymouth acpid ddcutil dmidecode mesa-utils ntfs-3g \
      vulkan-tools wayland-utils playerctl

# Fonts
RUN pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji

# CLI Utilities
RUN pacman -S --noconfirm sudo bash bash-completion fastfetch btop jq less lsof nano openssh powertop man-db \
      tree usbutils vim wget wl-clipboard unzip ptyxis glibc-locales tar udev starship tuned-ppd tuned hyfetch docker podman curl

# Drivers
RUN pacman -S --noconfirm amd-ucode intel-ucode efibootmgr shim mesa lib32-mesa libva-intel-driver libva-mesa-driver \
      vpl-gpu-rt vulkan-icd-loader vulkan-intel vulkan-radeon apparmor xf86-video-amdgpu lib32-vulkan-radeon 

# Network / VPN / SMB / storage
RUN pacman -S --noconfirm libmtp networkmanager-openconnect networkmanager-openvpn nss-mdns samba smbclient networkmanager firewalld udiskie \
      udisks2 

# Accessibility
RUN pacman -S --noconfirm espeak-ng orca

# Pipewire
RUN pacman -S --noconfirm pipewire pipewire-pulse pipewire-zeroconf pipewire-ffado pipewire-libcamera sof-firmware wireplumber

# Printer
RUN pacman -S --noconfirm cups cups-browsed hplip

# Desktop Environment needs
RUN pacman -S --noconfirm greetd xwayland-satellite greetd-regreet xdg-desktop-portal-kde xdg-desktop-portal xdg-user-dirs xdg-desktop-portal-gnome \
      ffmpegthumbs kdegraphics-thumbnailers kdenetwork-filesharing kio-admin chezmoi matugen accountsservice quickshell dgop cliphist cava dolphin \ 
      qt6ct breeze brightnessctl wlsunset ddcutil xdg-utils

# User frontend programs/apps
RUN pacman -S --noconfirm steam scx-scheds scx-manager gnome-disk-utility

# Add Maple Mono font, it's so cute! It's a pain to download! You'll love it.
RUN mkdir -p "/usr/share/fonts/Maple Mono" \
      && curl -fSsLo "/tmp/maple.zip" "$(curl "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | jq '.assets[] | select(.name == "MapleMono-Variable.zip") | .browser_download_url' -rc)" \
      && unzip "/tmp/maple.zip" -d "/usr/share/fonts/Maple Mono"

# Add Catppuccin cursor theme
RUN curl -L \
    -o /tmp/catppuccin-cursors.zip \
    https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-peach-cursors.zip && \
    unzip /tmp/catppuccin-cursors.zip -d /usr/share/icons/catppuccin-mocha-peach && \
    rm /tmp/catppuccin-cursors.zip

# Place XeniaOS logo at plymouth folder location to appear on boot and shutdown.
RUN wget -O /usr/share/plymouth/themes/spinner/watermark.png https://raw.githubusercontent.com/XeniaMeraki/XeniaOS-G-Euphoria/refs/heads/main/xeniaos_textlogo_plymouth_delphic_melody.png

RUN echo -ne '[Daemon]\nTheme=spinner' > /etc/plymouth/plymouthd.conf

#######################################################################################################################################################
# Section 1.5 - Package List | For my info and yours too! No secrets here. | Enjoy your life, and love everyone around you as much as possible ########
#######################################################################################################################################################

# -Package list- Chaotic-AUR precompiled packages
# niri-git | input-remapper-git | vesktop | sc-controller | flatpak-git | dms-shell-git | ttf-twemoji |
# ttf-symbola | opentabletdriver

# Arch apps
# Dolphin | Chezmoi | Gnome-Disks | Docker | Podman | SCX Manager | Steam

# Flatpaks
# Bazaar | Krita | Elisa | Pinta | OBS | Ark | Cave Story | Faugus Launcher | ProtonUp-QT | Kdenlive |
# Okular | Kate | Warehouse | Fedora Media Writer | Gear Lever | Haruna | Space Cadet Pinball | Gwenview
# Audacity | Filelight | Not Tetris 2 | Floorp

########################################################################################################################################
# Section 2 - Set up bootc dracut | I think it sets up the bootc initial image / Compiles Bootc Package :D #############################
########################################################################################################################################

# Workaround due to dracut version bump, please remove eventually
# FIXME: remove
RUN printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /etc/dracut.conf.d/fix-bootc.conf

RUN --mount=type=tmpfs,dst=/tmp --mount=type=tmpfs,dst=/root \
    pacman -S --noconfirm base-devel git rust && \
    git clone https://github.com/bootc-dev/bootc.git /tmp/bootc && \
    make -C /tmp/bootc bin install-all install-initramfs-dracut && \
    sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --add ostree --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"'

########################################################################################################################################
# Section 3 - Chaotic AUR # We grab some precompiled packages from the Chaotic AUR for things not on Arch repos/better updated~ ovo ####
########################################################################################################################################

RUN pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com

RUN pacman-key --init && pacman-key --lsign-key 3056513887B78AEB

RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm

RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm

RUN echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf

RUN pacman -Sy --noconfirm

RUN pacman -S \
      chaotic-aur/niri-git chaotic-aur/input-remapper-git chaotic-aur/vesktop-git chaotic-aur/sc-controller chaotic-aur/flatpak-git \
      chaotic-aur/dms-shell-git chaotic-aur/ttf-twemoji chaotic-aur/ttf-symbola chaotic-aur/opentabletdriver \
      --noconfirm

RUN systemctl enable greetd

########################################################################################################################################
# Section 4 Flatpaks preinstalls | We love containers, flatpaks, and protecting installs from breaking! ################################
########################################################################################################################################

RUN mkdir -p /usr/share/flatpak/preinstall.d/

# Bazaar
RUN printf "[Flatpak Preinstall io.github.kolunmi.Bazaar]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Bazaar.preinstall

# Krita
RUN printf "[Flatpak Preinstall org.kde.krita]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Krita.preinstall

# Elisa
RUN printf "[Flatpak Preinstall org.kde.elisa]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Elisa.preinstall

# Pinta | Image editing! They set out a bit to match paint.net/paintdotnet
RUN printf "[Flatpak Preinstall com.github.PintaProject.Pinta]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Pinta.preinstall

# OBS | Video recording/streaming!
RUN printf "[Flatpak Preinstall com.obsproject.Studio]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/OBS.preinstall

# OBSVKCapture | Games capture in OBS scenes on linux!
RUN printf "[Flatpak Preinstall com.obsproject.Studio.Plugin.OBSVkCapture]\nBranch=stable\nIsRuntime=true" > /usr/share/flatpak/preinstall.d/OBSVKCapture.preinstall

# Ark | For unzipping files and file compression! (Imagine a fox whose face you may squish...)
RUN printf "[Flatpak Preinstall org.kde.ark]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Ark.preinstall

# Cave Story, a free, public domain platformer! It"s historically important to videogames and platformers as a genre.
RUN printf "[Flatpak Preinstall com.gitlab.coringao.cavestory-nx]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/CaveStory.preinstall

# Faugus Launcher | This is fantastic for using windows software on linux, exes and whatnot
RUN printf "[Flatpak Preinstall io.github.faugus.faugus-launcher]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/FaugusLauncher.preinstall

# ProtonUp-Qt | For installing different versions of proton! Emulation for windows games via Steam/Valve's work
RUN printf "[Flatpak Preinstall net.davidotek.pupgui2]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/ProtonUp-Qt.preinstall

# Kdenlive | Video editing!
RUN printf "[Flatpak Preinstall org.kde.kdenlive]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Kdenlive.preinstall

# Okular | Viewing pdfs~
RUN printf "[Flatpak Preinstall org.kde.okular]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Okular.preinstall

# Kate | Writing documents~ Also can act as an IDE/development environment interestingly!
RUN printf "[Flatpak Preinstall org.kde.kate]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Kate.preinstall

# Warehouse | Manage your flatpak apps, delete whatever you don"t need/use/want! It's YOUR computer.
RUN printf "[Flatpak Preinstall io.github.flattool.Warehouse]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Warehouse.preinstall

# Fedora Media Writer | Burn ISOs to usb sticks! Install linux on ALL the things. (This won"t work for Windows ISOs, cuz Microsoft is dumb) >:c
RUN printf "[Flatpak Preinstall org.fedoraproject.MediaWriter]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/FedoraMediaWriter.preinstall

# Gear Lever | Manage appimages!
RUN printf "[Flatpak Preinstall it.mijorus.gearlever]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/GearLever.preinstall

# Haruna | Watch video files! I actually personally like this better than VLC Media Player, nicer look/featureset
RUN printf "[Flatpak Preinstall org.kde.haruna]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Haruna.preinstall

# Pinball | It's important. Shakes you. I need you to understand I NEED this and need to put this on your computer.
RUN printf "[Flatpak Preinstall com.github.k4zmu2a.spacecadetpinball]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Pinball.preinstall

# Gwenview | View images!
RUN printf "[Flatpak Preinstall org.kde.gwenview]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Gwenview.preinstall

# Audacity | Edit audio! We love Audacity~ Wonderful software.
RUN printf "[Flatpak Preinstall org.audacityteam.Audacity]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Audacity.preinstall

# Filelight | Check what's taking up space on your drives~
RUN printf "[Flatpak Preinstall org.kde.filelight]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Filelight.preinstall

# Not Tetris 2 | DEFINITELY not Tetris... 2!!!
RUN printf "[Flatpak Preinstall net.stabyourself.nottetris2]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/NotTetris2.preinstall

# Floorp | A very nicely fast and very nicely featured Firefox fork! A fellow fox!!
RUN printf "[Flatpak Preinstall one.ablaze.floorp]\nBranch=stable\nIsRuntime=false" > /usr/share/flatpak/preinstall.d/Floorp.preinstall

# Systemd flatpak preinstall service, thanks Zirconium
RUN echo -ne '[Unit]\n\
Description=Preinstall Flatpaks\n\
After=network-online.target\n\
Wants=network-online.target\n\
ConditionPathExists=/usr/bin/flatpak\n\
ConditionPathExists=!/var/lib/xeniaos/preinstall-finished\n\
Documentation=man:flatpak-preinstall(1)\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=mkdir -p /var/lib/xeniaos\n\
ExecStart=/usr/bin/flatpak preinstall -y\n\
ExecStart=touch /var/lib/xeniaos/preinstall-finished\n\
RemainAfterExit=true\n\
Restart=on-failure\n\
RestartSec=30\n\
\n\
StartLimitIntervalSec=600\n\
StartLimitBurst=3\n\
\n\
[Install]\n\
WantedBy=multi-user.target' > /usr/lib/systemd/system/flatpak-preinstall.service

RUN systemctl enable flatpak-preinstall.service

########################################################################################################################################
# Section 5 - Linux OS stuffs | We set some nice defaults for a regular user + set up a few XeniaOS details owo #####################
########################################################################################################################################

# Add user to sudoers file for sudo, enable polkit
RUN echo "%wheel      ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
RUN systemctl enable polkit

# Set up zram, this will help users not run out of memory. Fox will fix!
RUN echo -ne '[zram0]\nzram-size = min(ram, 8192)' >> /usr/lib/systemd/zram-generator.conf
RUN echo -ne 'enable systemd-resolved.service' >> usr/lib/systemd/system-preset/91-resolved-default.preset
RUN echo -ne 'L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf' >> /usr/lib/tmpfiles.d/resolved-default.conf
RUN systemctl preset systemd-resolved.service

# Enable wifi, firewall, power profiles. Fox will protect!
RUN systemctl enable NetworkManager tuned tuned-ppd firewalld

# OS Release and Update uwu
RUN echo -ne 'NAME="XeniaOS"\n\
PRETTY_NAME="XeniaOS"\n\
ID=arch\n\
BUILD_ID=rolling\n\
ANSI_COLOR="38;2;23;147;209"\n\
HOME_URL="https://github.com/XeniaMeraki/XeniaOS"\n\
LOGO=archlinux-logo\n\
DEFAULT_HOSTNAME="XeniaOS"' > /etc/os-release

# Automounter Systemd Service for flash drives and CDs
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
WantedBy=graphical-session.target\n' > /usr/lib/systemd/user/udiskie.service

# Clip history / Cliphist systemd service / Clipboard history for copy and pasting to work properly in Niri~
RUN echo -ne '[Unit]\n\
Description=Clipboard History service\n\
PartOf=graphical-session.target\n\
After=graphical-session.target\n\
\n\
[Service]\n\
ExecStart=wl-paste --watch cliphist store\n\
Restart=on-failure\n\
RestartSec=1\n\
\n\
[Install]\n\
WantedBy=graphical-session.target' > /usr/lib/systemd/user/cliphist.service

# Symlink Vi to Vim / Make it to where a user can use vi in terminal command to use vim automatically | Thanks Tulip
RUN ln -s ./vim /usr/bin/vi

# System-wide default application associations for filetype calls
RUN mkdir -p /etc/xdg/

RUN echo -ne '[Default Applications]\n\
text/plain=org.kde.kate.desktop\n\
application/json=org.kde.kate.desktop\n\
\n\
text/html=floorp.desktop\n\
\n\
video/mp4=haruna.desktop\n\
video/x-matroska=haruna.desktop\n\
video/webm=haruna.desktop\n\
video/quicktime=haruna.desktop\n\
\n\
audio/mpeg=org.kde.elisa.desktop\n\
audio/flac=org.kde.elisa.desktop\n\
audio/ogg=org.kde.elisa.desktop\n\
audio/wav=org.kde.elisa.desktop\n\
\n\
image/png=pinta.desktop\n\
image/jpeg=pinta.desktop\n\
image/gif=org.kde.gwenview.desktop\n\
\n\
application/zip=org.kde.ark.desktop\n\
application/x-rar=org.kde.ark.desktop\n\
application/x-tar=org.kde.ark.desktop\n\
\n\
[Added Associations]' > /etc/xdg/mimeapps.list

# ENV default exports, QT theming 
# Load shared objects immediately for better first time latency
# Apply OBS_VK to all vulkan instances for better OBS game capture, some other windows may come along for the ride
ENV QT_QPA_PLATFORMTHEME=qt6ct
ENV LD_BIND_NOW=1
ENV OBS_VKCAPTURE=1

# Set vm.max_map_count for stability/improved gaming performance
# https://wiki.archlinux.org/title/Gaming#Increase_vm.max_map_count
RUN echo -ne "vm.max_map_count = 2147483642" > /etc/sysctl.d/80-gamecompatibility.conf

# Automount removable disks to /media/ using udisks2
# https://wiki.archlinux.org/title/Udisks
RUN echo -ne 'ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="1"' > /etc/udev/rules.d/99-udisks2.rules

RUN echo -ne 'D /media 0755 root root 0 -' > /etc/tmpfiles.d/media.conf

########################################################################################################################################
# Section 6 - CachyOS settings | Since we have the CachyOS kernel, we gotta put it to good use ≽^•⩊•^≼ ################################
########################################################################################################################################

# Activate NTSync, wags my tail in your general direction
RUN echo 'ntsync' > /etc/modules-load.d/ntsync.conf

# CachyOS bbr3 Config Option
RUN echo -ne 'net.core.default_qdisc=fq \n\
net.ipv4.tcp_congestion_control=bbr\n' > /etc/sysctl.d/99-bbr3.conf

########################################################################################################################################
# Section 7 - Niri/Chezmoi/DMS | Everything to do with the desktop/visual look of your taskbar/ config files (⸝⸝>w<⸝⸝) #################
########################################################################################################################################

# Add config for dolphin to Niri and switch away from GTK/Nautilus, use Dolphin for file chooser.
RUN echo -ne '[preferred] \n\
default=kde;gtk;gnome; \n\
org.freedesktop.impl.portal.ScreenCast=gnome;kde;gtk; \n\
org.freedesktop.impl.portal.Access=kde;gtk;gnome; \n\
org.freedesktop.impl.portal.Notification=kde;gtk;gnome; \n\
org.freedesktop.impl.portal.Secret=gnome-keyring' > /usr/share/xdg-desktop-portal/niri-portals.conf

# Use Chezmoi to set up config files, visual assets, avatars, and wallpapers
RUN mkdir -p /usr/share/xeniaos/ && \
      git clone https://github.com/XeniaMeraki/XeniaOS-HRT /usr/share/xeniaos/zdots

RUN mkdir -p /usr/share/xeniaos/ && \
      git clone https://github.com/XeniaMeraki/XeniaOS-G-Euphoria /usr/share/xeniaos/wallpapers

#Starship setup
RUN echo 'eval "$(starship init bash)"' >> /etc/bash.bashrc

# DMS Service Systemd Service
RUN echo -ne '[Unit]\n\
Description=Shell Service\n\
PartOf=graphical-session.target\n\
After=graphical-session.target\n\
\n\
[Service]\n\
ExecStart=dms run\n\
Restart=on-failure\n\
RestartSec=1\n\
\n\
[Install]\n\
WantedBy=graphical-session.target\n' > /usr/lib/systemd/user/dms.service

# Starts with Niri Session - Services for User Interaction
RUN sed -i "s/\[Unit\]/\[Unit\]\nWants=udiskie.service/" "/usr/lib/systemd/user/niri.service"
RUN sed -i "s/\[Unit\]/\[Unit\]\nWants=plasma-xdg-desktop-portal-kde.service/" "/usr/lib/systemd/user/niri.service"
RUN sed -i "s/\[Unit\]/\[Unit\]\nWants=dms.service/" "/usr/lib/systemd/user/niri.service"
RUN sed -i "s/\[Unit\]/\[Unit\]\nWants=cliphist.service/" "/usr/lib/systemd/user/niri.service"

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
WantedBy=default.target\n' >> /usr/lib/systemd/user/chezmoi-init.service

RUN echo -ne "[Unit]\n\
Description=Chezmoi Update\n\
\n\
[Service]\n\
ExecStart=mkdir -p %h/.config/xeniaos/chezmoi\n\
ExecStart=touch %h/.config/xeniaos/chezmoi/chezmoi.toml\n\
ExecStart=sh -c 'yes s | chezmoi apply --no-tty --keep-going -S /usr/share/xeniaos/zdots --verbose --config %h/.config/xeniaos/chezmoi/chezmoi.toml'\n\
Type=oneshot\n" >> /usr/lib/systemd/user/chezmoi-update.service

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
WantedBy=timers.target\n' >> /usr/lib/systemd/user/chezmoi-update.timer

# Create greeter user (required)
RUN useradd -m -G video,input -s /usr/bin/nologin greeter

# Regreeter login shell setup
RUN mkdir -p /etc/greetd/

RUN echo -ne 'spawn-sh-at-startup "regreet; niri msg action quit --skip-confirmation"\n\
hotkey-overlay {\n\
    skip-at-startup\n\
}\n\
cursor {\n\
    xcursor-theme "catppuccin-mocha-peach"\n\
}' > /etc/greetd/niri.kdl

RUN echo -ne '[terminal]\n\
vt = 1\n\
\n\
[default_session]\n\
command = "niri --config /etc/greetd/niri.kdl"\n\
user = "greeter"' > /etc/greetd/config.toml

RUN echo -ne '[background]\n\
path = "/usr/share/xeniaos/wallpapers/3_hypno_chimmie_firefly_videorelaxant6025.png"\n\
\n\
fit = "Contain"\n\
\n\
cursor_theme_name = "Catppuccin-Mocha-Peach"\n\
\n\
cursor_blink = true\n\
\n\
greeting_msg = "Welcome to the fox den!"\n\
\n\
font_name = "Maple Mono 16"\n\
\n\
format = "%a %H:%M"\n\
\n\
application_prefer_dark_theme = true' > /etc/greetd/regreet.toml

RUN systemctl enable --global chezmoi-init.service chezmoi-update.timer

RUN systemctl enable --global dms.service

########################################################################################################################################
# Section 8 - Final Bootc Setup. The horrors are endless. but we stay silly :3c -junoinfernal -maia arson crimew #######################
########################################################################################################################################

# This fixes a user/groups error with Arch Bootc setup.
# FIXME Do NOT remove until fixed upstream. Script created by Tulip.

RUN mkdir -p /usr/lib/systemd/system-preset /usr/lib/systemd/system

RUN echo -ne '#!/bin/sh\ncat /usr/lib/sysusers.d/*.conf | grep -e "^g" | grep -v -e "^#" | awk "NF" | awk '\''{print $2}'\'' | grep -v -e "wheel" -e "root" -e "sudo" | xargs -I{} sed -i "/{}/d" $1' > /usr/libexec/xeniaos-group-fix
RUN chmod +x /usr/libexec/xeniaos-group-fix
RUN echo -ne '[Unit]\n\
Description=Fix groups\n\
Wants=local-fs.target\n\
After=local-fs.target\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/libexec/xeniaos-group-fix /etc/group\n\
ExecStart=/usr/libexec/xeniaos-group-fix /etc/gshadow\n\
ExecStart=systemd-sysusers\n\
[Install]\n\
WantedBy=default.target multi-user.target\n' > /usr/lib/systemd/system/xeniaos-group-fix.service

RUN echo "enable xeniaos-group-fix.service" > /usr/lib/systemd/system-preset/01-xeniaos-group-fix.preset
RUN systemctl enable xeniaos-group-fix.service

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

RUN bootc container lint

#####################                                                       ✧⋆✩₊⋆⁺₊˚.
#####################     ,c.                       .c;                    ✩₊˚.⋆☾⋆⁺₊✧
#####################   .KMMMk....             ....kMMMK.                  ₊˚.⋆⁺₊✧⋆✩
#####################   .WMMMMMX.....         .....KMMMMMW.                       
#####################   XMMMMMMM0.....        ....OMMMMMMMN
#####################  dMMMMMMMMM;.... ..... ....,MMMMMMMMMd
#####################  WMMMMMMMMMl;okKKKKKKKKKOo;cMMMMMMMMMM
##################### 'MMMMMMMNXK0KKKKKKKKKKKKKKK0KXNMMMMMMM;
##################### oMMMMMMMOxoKKKKKKKKKKKKKKKKKoxOMMMMMMMd
##################### dMMMMMMMdxxxKKKKKKKKKKKKKKKxxxdNMMMMMMk
##################### :MMMMX0xxxxxx0KKKKKKKK0KK0xxxxxx0XMMMMc
#####################  MMMOxxxxxxxxdxkdd0x0ddkxdxxxxxxxxOMMM
##################### ;xxkxddxxxxdodxxxxdxdxxxxdodxxxxddxkxx;
#####################dxdKMMMWXo'.....'cdxxxdc'.....'lXWMMMXdxd
##################### cxdXMMMN,..........dxd'.........'XMMMNdxl
#####################  .xxWMMl...''....'.;k:.'....''...lMMWxx.
##################### ..:kXMMx..'....''..kMk..''....'..xMMXkc..
#####################  dMMMMMMd.....'...xMMMx...''....dMMMMMMx
#####################    kMMMMWOoc:coOkolllokOoc:coOWMMMMO
#####################          .MMMMMMMMl...lNMMMMMMM.
#####################             KMMMMMMXlKMMMMMMX
#####################                .MMMMMMMMM. 
#####################
##################### Art by @bhavyakukkar and @ioletsgo
