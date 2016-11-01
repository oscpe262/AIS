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

host_name="fooputer"
HOOKSLIST="base udev autodetect modconf block filesystems keyboard fsck mdadm_udev"
MODULESLIST="sata_sil"

root_password(){
  print_title "ROOT PASSWORD"
  print_warning "Enter your new root password"
  arch_chroot "passwd"
  pause_function
}

mirrorlist_gen() {
  country_name=Sweden
  url="https://www.archlinux.org/mirrorlist/?country=SE&use_mirror_status=onhttps://www.archlinux.org/mirrorlist/?country=SE&use_mirror_status=on"
  tmpfile=$(mktemp --suffix=-mirrorlist)

  curl -so ${tmpfile} ${url}
  sed -i 's/^#Server/Server/g' ${tmpfile}

    if [[ -s ${tmpfile} ]]; then
     { echo " Backing up the original mirrorlist..."
       mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig; } &&
     { echo " Rotating the new list into place..."
       mv -i ${tmpfile} /etc/pacman.d/mirrorlist; }
    else
      echo " Unable to update, could not download list."
    fi
    # better repo should go first
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
    rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
    rm /etc/pacman.d/mirrorlist.tmp
    # allow global read access (required for non-root yaourt execution)
    chmod +r /etc/pacman.d/mirrorlist
    $EDITOR /etc/pacman.d/mirrorlist

  cat <<- EOF > /etc/resolv.conf.head
  nameserver 8.8.8.8
  nameserver 8.8.4.4
  nameserver 2001:4860:4860::8888
  nameserver 2001:4860:4860::8844
  EOF
}

install_base_system() {
  print_title "BASE SYSTEM INSTALL"
  print_info "Pacstrapping and installing base_devel package group plus some other basic stuff."
  rm ${MOUNTPOINT}${EFI_MOUNTPOINT}/vmlinuz-linux
  pacstrap ${MOUNTPOINT} base basedevel parted zsh f2fs-tools ntp gptfdisk
  [[ $? -ne 0 ]] && error_msg "Install failed!"
  WIRELESS_DEV=`ip link | grep wlp | awk '{print $2}'| sed 's/://' | sed '1!d'`
    if [[ -n $WIRELESS_DEV ]]; then
      pacstrap ${MOUNTPOINT} iw wireless_tools wpa_actiond wpa_supplicant dialog
    fi
  WIRED_DEV=`ip link | grep "ens\|eno\|enp" | awk '{print $2}'| sed 's/://' | sed '1!d'`
    if [[ -n $WIRED_DEV ]]; then
      arch_chroot "systemctl enable dhcpcd@${WIRED_DEV}.service"
    fi
}

install_bootloader() {
  pacstrap ${MOUNTPOINT} grub os-prober
  [[ $UEFI -eq 1 ]] && pacstrap ${MOUNTPOINT} efibootmgr dosfstools
  if [[ $UEFI -eq 1 ]]; then
    arch_chroot "grub-install --target=x86_64-efi --efi-directory=${EFI_MOUNTPOINT} --bootloader-id=arch_grub --recheck"
  else
    arch_chroot "grub-install --target=i386-pc --recheck --debug ${BOOT_MOUNTPOINT}"
  fi
  arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}

finish() {
  print_title "INSTALL COMPLETE"
  print_warning "\nA copy of these scripts will be placed in /root on the new system."
  cp -R `pwd` ${MOUNTPOINT}/root
  read_input_text "Reboot system"
  if [[ $OPTION == y ]]; then
    for i in `lsblk | grep ${MOUNTPOINT} | awk '{print $7}' | sort -r`; do
      unmount $i
    done
    reboot
  fi
  exit 0
}
