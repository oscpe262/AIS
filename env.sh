#!/bin/bash
################################################################################
#Created by Splatrat: oscpe262[at]gmail[dot]com
#Based on the works of helmuthdu
################################################################################
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

if [[ -f `pwd`/shared.sh ]]; then
  source shared.sh
else
  echo "missing file: shared.sh"
  exit 1
fi
if [[ -f `pwd`/envfuncs.sh ]]; then
  source envfuncs.sh
else
  echo "missing file: shared.sh"
  exit 1
fi

#NOTES: TODO
# transmission config

AUTOMATIC_MODE=1
ZFS=0
SAMBA=0
PMS=0
WEB=0

print_title "ADDING USERS"
POWERUSER=1
main_user="splatrat"
create_new_user ${main_user}
POWERUSER=0
create_new_user "malin"
create_new_user "julia"
create_new_user "simba"
username=${main_user}

configure_sudo
install_yaourt
install_basic_setup
install_ssh
install_nfs
install_samba
install_xorg
#fonts config, tba
install_vga
#cups tba
package_install "bluez-firmware libmtp"
aur_package_install "alsa-firmware android-udev"
install_desktop_environment
install_network
install_servers
pacman -Rsc --noconfirm $(pacman -Qqdt)
reconfigure_system
