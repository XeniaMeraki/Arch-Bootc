#!/usr/bin/env bash

set -xeuo pipefail

cp -avf "/ctx/files"/. /

add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
add_wants_niri plasma-polkit-agent.service
add_wants_niri udiskie.service
add_wants_niri xwayland-satellite.service
cat /usr/lib/systemd/user/niri.service

systemctl enable greetd

