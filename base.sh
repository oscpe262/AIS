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
if [[ -f `pwd`/basefuncs ]]; then
  source basefuncs.sh
else
  echo "missing file: basefuncs.sh"
  exit 1
fi

check_boot_system
check_connection
check_root
check_archlinux
pacman -Sy

print_title "Arch Linux Install Script"
print_line
print_info "This script does not have dynamic disk setup. Make sure it is properly configured before you proceed!"
read_input_text "Do you wish to proceed?"
[[ ! $OPTION == y ]] && exit 1


#INSTALL EDITOR
package_install emacs
select_editor

#MIRRORLIST
mirrorlist_gen

#DISK SETUP
check_boot_system
mount ${ROOT_PARTITION} ${MOUNTPOINT}
[[ -f ${MOUNTPOINT}/boot ]] || mkdir -p ${MOUNTPOINT}/boot
[[ -z ${BOOT_PARTITION} ]] || mount ${BOOT_PARTITION} ${MOUNTPOINT}/boot
if [[ ${UEFI} == 1 ]]; then
  mkdir -p ${MOUNTPOINT}${EFI_MOUNTPOINT}
fi
[[ -z ${HOME_PARTITION} ]] || mount ${HOME_PARTITION} ${MOUNTPOINT}/home

#INSTALL BASE SYSTEM
install_base_system

#CONFIG FSTAB
print_title "FSTAB SETUP"
genfstab -t PARTUUID -p ${MOUNTPOINT} >> ${MOUNTPOINT}/etc/fstab
sed -i "s/\\${MOUNTPOINT}//" ${MOUNTPOINT}/etc/fstab
pause_function
emacs ${MOUNTPOINT}/etc/fstab # check editor set ...

#HOSTNAME
print_title "HOSTNAME/TIME SETUP"
echo "$host_name" > ${MOUNTPOINT}/etc/hostname
arch_chroot "sed -i '/127.0.0.1/s/$/ '${host_name}'/' /etc/hosts"
arch_chroot "sed -i '/::1/s/$/ '${host_name}'/' /etc/hosts"

#TIME STUFF
settimezone

#LOCALE
print_title "LOCALE SETUP"
genlocale() {
  arch_chroot "sed -i '/'${1}.UTF8'/s/^#//' /etc/locale.gen"
}
genlocale "en_GB"
genlocale "sv_SE"
echo 'LANG=en_GB.UTF8"' > ${MOUNTPOINT}/etc/locale.conf
arch_chroot "locale-gen"

#MKINITCPIO
print_title "MKINITCPIO"
sed -i "s/^HOOKS=*/HOOKS=\"${HOOKSLIST}\"/g" ${MOUNTPOINT}/etc/mkinitcpio.conf
sed -i "s/^MODULES=*/MODULES=\"${MODULESLIST}\"/g" ${MOUNTPOINT}/etc/mkinitcpio.conf
arch_chroot "mkinitcpio -p linux"

#BOOTLOADER
print_title "BOOTLOADER SETUP"
print_info "Installing Grub2 ..."
install_bootloader

#ROOT PASSWORD
root_password

#FINISH AND REBOOT
finish
