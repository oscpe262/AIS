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

create_new_user() {
  username=`echo ${1} | tr '[:upper:]' '[:lower:]'`
  if [[ $POWERUSER -eq 1 ]]; then
  print_info "Adding POWERUSER ${username}"
    useradd -m -g users -G wheel -s /bin/zsh ${username}
  else
  print_info "Adding regular user ${username}"
    useradd -m -g users -s /bin/bash ${username}
  fi
  passwd ${username}
  while [[ $? -ne 0 ]]; do
    passwd ${username}
  done
  pause_function
  configure_user_account
}

configure_user_account() {
  package_install "git"
  if [[ $POWERUSER -eq 1 ]]; then
    git clone https://github.com/oscpe262/zsh.d.git
    cp -R zsh.d /etc/zsh/
    mv /etc/zsh/zsh.d/zshrc /etc/zsh/zshrc
    touch /home/${username}/.aliases
    sed -i "s/CONTEXT_FG*/CONTEXT_FG=$((RANDOM%255)))/g" /etc/zsh/zsh.d/btconf.sh
    chown ${username} /etc/zsh/zsh.d -R
    rm -rf zsh.d
  else
    cp /etc/skel/.bashrc /home/${username}/
  fi
  package_install "emacs"
  chown -R ${username}:${username} /home/${username}
}

configure_sudo() {
  if ! is_package_installed "sudo" ; then
    print_title "SUDO - https://wiki.archlinux.org/index.php/Sudo"
    package_install "sudo"
  fi
  #CONFIGURE SUDOERS
  if [[ ! -f  /etc/sudoers.aui ]]; then
    cp -v /etc/sudoers /etc/sudoers.aui
    ## Uncomment to allow members of group wheel to execute any command
    sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers
    ## Same thing without a password (not secure)
    #sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers

    #This config is especially helpful for those using terminal multiplexers like screen, tmux, or ratpoison, and those using sudo from scripts/cronjobs:
    echo "" >> /etc/sudoers
    echo 'Defaults !requiretty, !tty_tickets, !umask' >> /etc/sudoers
    echo 'Defaults visiblepw, path_info, insults, lecture=always' >> /etc/sudoers
    echo 'Defaults loglinelen=0, logfile =/var/log/sudo.log, log_year, log_host, syslog=auth' >> /etc/sudoers
    echo 'Defaults passwd_tries=3, passwd_timeout=1' >> /etc/sudoers
    echo 'Defaults env_reset, always_set_home, set_home, set_logname' >> /etc/sudoers
    echo 'Defaults !env_editor, editor="/usr/bin/vim:/usr/bin/vi:/usr/bin/nano"' >> /etc/sudoers
    echo 'Defaults timestamp_timeout=15' >> /etc/sudoers
    echo 'Defaults passprompt="[sudo] password for %u: "' >> /etc/sudoers
  fi

install_yaourt() {
  print_title "YAOURT - https://wiki.archlinux.org/index.php/Yaourt"
  print_info "Yaourt (Yet AnOther User Repository Tool) is a community-contributed wrapper for pacman which adds seamless access to the AUR, allowing and automating package compilation and installation from your choice of the thousands of PKGBUILDs in the AUR, in addition to the many thousands of available Arch Linux binary packages."
  if ! is_package_installed "yaourt" ; then
    package_install "base-devel yajl namcap"
    pacman -D --asdeps yajl namcap
    aui_download_packages "package-query yaourt"
    pacman -D --asdeps package-query
    if ! is_package_installed "yaourt" ; then
      echo "Yaourt not installed. EXIT now"
      pause_function
      exit 0
    fi
  fi
  AUR_PKG_MANAGER="yaourt --tmp /var/tmp/"
}

install_basic_setup() {
  print_title "BASH TOOLS - https://wiki.archlinux.org/index.php/Bash"
  package_install "bc rsync mlocate bash-completion pkgstats arch-wiki-lite"
  pause_function
  print_title "(UN)COMPRESS TOOLS - https://wiki.archlinux.org/index.php/P7zip"
  package_install "zip unzip unrar p7zip lzop cpio"
  pause_function
  print_title "AVAHI - https://wiki.archlinux.org/index.php/Avahi"
  print_info "Avahi is a free Zero Configuration Networking (Zeroconf) implementation, including a system for multicast DNS/DNS-SD discovery. It allows programs to publish and discovers services and hosts running on a local network with no specific configuration."
  package_install "avahi nss-mdns"
  is_package_installed "avahi" && system_ctl enable avahi-daemon
  pause_function
  print_title "ALSA - https://wiki.archlinux.org/index.php/Alsa"
  print_info "The Advanced Linux Sound Architecture (ALSA) is a Linux kernel component intended to replace the original Open Sound System (OSSv3) for providing device drivers for sound cards."
  package_install "alsa-utils alsa-plugins"
  [[ ${ARCHI} == x86_64 ]] && package_install "lib32-alsa-plugins"
  pause_function
  print_title "PULSEAUDIO - https://wiki.archlinux.org/index.php/Pulseaudio"
  print_info "PulseAudio is the default sound server that serves as a proxy to sound applications using existing kernel sound components like ALSA or OSS"
  package_install "pulseaudio pulseaudio-alsa"
  [[ ${ARCHI} == x86_64 ]] && package_install "lib32-libpulse"
  pause_function
  print_title "NTFS/FAT/exFAT/F2FS - https://wiki.archlinux.org/index.php/File_Systems"
  print_info "A file system (or filesystem) is a means to organize data expected to be retained after a program terminates by providing procedures to store, retrieve and update data, as well as manage the available space on the device(s) which contain it. A file system organizes data in an efficient manner and is tuned to the specific characteristics of the device."
  package_install "ntfs-3g dosfstools exfat-utils f2fs-tools fuse fuse-exfat autofs mtpfs"
  [[ $ZFS -eq 1 ]] && package_install "zfs-linux-git"
}

install_ssh(){
  print_title "SSH - https://wiki.archlinux.org/index.php/Ssh"
  print_info "Secure Shell (SSH) is a network protocol that allows data to be exchanged over a secure channel between two computers."
  package_install "openssh"
  system_ctl enable sshd
  [[ ! -f /etc/ssh/sshd_config.aui ]] && cp -v /etc/ssh/sshd_config /etc/ssh/sshd_config.aui;
  #CONFIGURE SSHD_CONF #{{{
    sed -i '/Port 22/s/^#//' /etc/ssh/sshd_config
    sed -i '/Protocol 2/s/^#//' /etc/ssh/sshd_config
    sed -i '/HostKey \/etc\/ssh\/ssh_host_rsa_key/s/^#//' /etc/ssh/sshd_config
    sed -i '/HostKey \/etc\/ssh\/ssh_host_dsa_key/s/^#//' /etc/ssh/sshd_config
    sed -i '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/s/^#//' /etc/ssh/sshd_config
    sed -i '/KeyRegenerationInterval/s/^#//' /etc/ssh/sshd_config
    sed -i '/ServerKeyBits/s/^#//' /etc/ssh/sshd_config
    sed -i '/SyslogFacility/s/^#//' /etc/ssh/sshd_config
    sed -i '/LogLevel/s/^#//' /etc/ssh/sshd_config
    sed -i '/LoginGraceTime/s/^#//' /etc/ssh/sshd_config
    #sed -i '/PermitRootLogin/s/^#//' /etc/ssh/sshd_config
    sed -i '/HostbasedAuthentication/s/^#//' /etc/ssh/sshd_config
    sed -i '/StrictModes/s/^#//' /etc/ssh/sshd_config
    sed -i '/RSAAuthentication/s/^#//' /etc/ssh/sshd_config
    sed -i '/PubkeyAuthentication/s/^#//' /etc/ssh/sshd_config
    sed -i '/IgnoreRhosts/s/^#//' /etc/ssh/sshd_config
    sed -i '/PermitEmptyPasswords/s/^#//' /etc/ssh/sshd_config
    sed -i '/AllowTcpForwarding/s/^#//' /etc/ssh/sshd_config
    sed -i '/AllowTcpForwarding no/d' /etc/ssh/sshd_config
    sed -i '/X11Forwarding/s/^#//' /etc/ssh/sshd_config
    sed -i '/X11Forwarding/s/no/yes/' /etc/ssh/sshd_config
    sed -i -e '/\tX11Forwarding yes/d' /etc/ssh/sshd_config
    sed -i '/X11DisplayOffset/s/^#//' /etc/ssh/sshd_config
    sed -i '/X11UseLocalhost/s/^#//' /etc/ssh/sshd_config
    sed -i '/PrintMotd/s/^#//' /etc/ssh/sshd_config
    sed -i '/PrintMotd/s/yes/no/' /etc/ssh/sshd_config
    sed -i '/PrintLastLog/s/^#//' /etc/ssh/sshd_config
    sed -i '/TCPKeepAlive/s/^#//' /etc/ssh/sshd_config
    sed -i '/the setting of/s/^/#/' /etc/ssh/sshd_config
    sed -i '/RhostsRSAAuthentication and HostbasedAuthentication/s/^/#/' /etc/ssh/sshd_config
    pause_function
}

install_nfs(){
  print_title "NFS - https://wiki.archlinux.org/index.php/Nfs"
  print_info "NFS allowing a user on a client computer to access files over a network in a manner similar to how local storage is accessed."
    package_install "nfs-utils"
    system_ctl enable rpcbind
    system_ctl enable nfs-client.target
    system_ctl enable remote-fs.target
    pause_function
}

install_samba(){
  print_title "SAMBA - https://wiki.archlinux.org/index.php/Samba"
  print_info "Samba is a re-implementation of the SMB/CIFS networking protocol, it facilitates file and printer sharing among Linux and Windows systems as an alternative to NFS."
  if [[ $SAMBA == 1 ]]; then
    package_install "samba smbnetfs"
    [[ ! -f /etc/samba/smb.conf ]] && cp /etc/samba/smb.conf.default /etc/samba/smb.conf
    local CONFIG_SAMBA=`cat /etc/samba/smb.conf | grep usershare`
    if [[ -z $CONFIG_SAMBA ]]; then
      # configure usershare
      export USERSHARES_DIR="/var/lib/samba/usershare"
      export USERSHARES_GROUP="sambashare"
      mkdir -p ${USERSHARES_DIR}
      groupadd ${USERSHARES_GROUP}
      chown root:${USERSHARES_GROUP} ${USERSHARES_DIR}
      chmod 1770 ${USERSHARES_DIR}
      sed -i -e '/\[global\]/a\\n   usershare path = /var/lib/samba/usershare\n   usershare max shares = 100\n   usershare allow guests = yes\n   usershare owner only = False' /etc/samba/smb.conf
      sed -i -e '/\[global\]/a\\n   socket options = IPTOS_LOWDELAY TCP_NODELAY SO_KEEPALIVE\n   write cache size = 2097152\n   use sendfile = yes\n' /etc/samba/smb.conf
      usermod -a -G ${USERSHARES_GROUP} ${username}
      sed -i '/user_allow_other/s/^#//' /etc/fuse.conf
      modprobe fuse
    fi
    echo "Enter your new samba account password:"
    pdbedit -a -u ${username}
    while [[ $? -ne 0 ]]; do
      pdbedit -a -u ${username}
    done
    # enable services
    system_ctl enable smbd
    system_ctl enable nmbd
    pause_function
  fi
}

install_xorg(){
  print_title "XORG - https://wiki.archlinux.org/index.php/Xorg"
  print_info "Xorg is the public, open-source implementation of the X window system version 11."
  echo "Installing X-Server (req. for Desktopenvironment, GPU Drivers, Keyboardlayout,...)"
  package_install "xorg-server xorg-server-utils xorg-server-xwayland xorg-xinit xorg-xkill"
  package_install "xf86-input-synaptics xf86-input-mouse xf86-input-keyboard xf86-input-wacom xf86-input-joystick xf86-input-libinput"
  package_install "mesa"
  modprobe uinput
  pause_function
}

install_vga() {
  package_install "dmidecode"
  print_title "VIDEO CARD"
  check_vga
##virtualbox
  if [[ ${VIDEO_DRIVER} == virtualbox ]]; then
    package_install "virtualbox-guest-modules-arch mesa-libgl"
    add_module "vboxguest vboxsf vboxvideo" "virtualbox-guest"
    add_user_to_group ${username} vboxsf
    system_ctl disable ntpd
    system_ctl enable vboxservice
##Bumblebee
  elif [[ ${VIDEO_DRIVER} == bumblebee ]]; then
    XF86_DRIVERS=$(pacman -Qe | grep xf86-video | awk '{print $1}')
    [[ -n $XF86_DRIVERS ]] && pacman -Rcsn $XF86_DRIVERS
    pacman -S --needed xf86-video-intel bumblebee nvidia
    [[ ${ARCHI} == x86_64 ]] && pacman -S --needed lib32-nvidia-utils
    replace_line '*options nouveau modeset=1' '#options nouveau modeset=1' /etc/modprobe.d/modprobe.conf
    replace_line '*MODULES="nouveau"' '#MODULES="nouveau"' /etc/mkinitcpio.conf
    mkinitcpio -p linux
    add_user_to_group ${username} bumblebee
##NVIDIA
  elif [[ ${VIDEO_DRIVER} == nvidia ]]; then
    XF86_DRIVERS=$(pacman -Qe | grep xf86-video | awk '{print $1}')
    [[ -n $XF86_DRIVERS ]] && pacman -Rcsn $XF86_DRIVERS
    package_install "libva-vdpau-driver"
    pacman -S --needed nvidia{,-utils}
    [[ ${ARCHI} == x86_64 ]] && pacman -S --needed lib32-nvidia-utils
    replace_line '*options nouveau modeset=1' '#options nouveau modeset=1' /etc/modprobe.d/modprobe.conf
    replace_line '*MODULES="nouveau"' '#MODULES="nouveau"' /etc/mkinitcpio.conf
    mkinitcpio -p linux
    nvidia-xconfig --add-argb-glx-visuals --allow-glx-with-composite --composite -no-logo --render-accel -o /etc/X11/xorg.conf.d/20-nvidia.conf;
#ATI
  elif [[ ${VIDEO_DRIVER} == ati ]]; then
    is_package_installed "catalyst-total" && pacman -Rdds --noconfirm catalyst-total
    [[ -f /etc/X11/xorg.conf.d/20-radeon.conf ]] && rm /etc/X11/xorg.conf.d/20-radeon.conf
    [[ -f /etc/modules-load.d/catalyst.conf ]] && rm /etc/modules-load.d/catalyst.conf
    [[ -f /etc/X11/xorg.conf ]] && rm /etc/X11/xorg.conf
    package_install "xf86-video-${VIDEO_DRIVER} mesa-libgl mesa-vdpau libva-vdpau-driver"
    add_module "radeon" "ati"
##Intel
  elif [[ ${VIDEO_DRIVER} == intel ]]; then
    package_install "xf86-video-${VIDEO_DRIVER} mesa-libgl libva-intel-driver"
## VESA
  else
    package_install "xf86-video-${VIDEO_DRIVER} mesa-libgl libva-vdpau-driver"
  fi
  if [[ ${ARCHI} == x86_64 ]]; then
    is_package_installed "mesa-libgl" && package_install "lib32-mesa-libgl"
    is_package_installed "mesa-vdpau" && package_install "lib32-mesa-vdpau"
  fi
  if is_package_installed "libva-vdpau-driver"; then
    add_line "export LIBVA_DRIVER_NAME=vdpau" "/etc/profile"
  fi
  pause_function
}

install_desktop_environment() {
  print_title "DESKTOP ENVIRONMENT"
  aur_package_install "numix-icon-theme-git numix-circle-icon-theme-git"
  package_install "lightdm lightdm-gtk-greeter"
  system_ctl enable lightdm
  package_install "dmenu rxvt-unicode thunar compton gvfs-mtp xdg-user-dirs pavucontrol km_sensors"
  package_install "ttf-dejavu ttf-bitstream-vera powerline-common powerline-fonts"
  aur_package_install "gnome-defaults-list"
  is_package_installed "samba" && package_install "gvfs-smb"
  package_install "i3"
  sensors-detect --auto
  system_ctl enable accounts-daemon
  package_install "galculator"
}

install_network() {
  package_install "networkmanager dnsmasq network-manager-applet nm-connection-editor"
  is_package_installed "ntp" && package_install "networkmanager-dispatcher-ntpd"
  system_ctl enable NetworkManager.service
  system_ctl enable networkmanager-dispatcher.service
}

install_apps() {
  aur_package_install "atom-editor-bin jdk"
  package_install "emacs texlive-most texlive-bin libreoffice-fresh gparted htop"
  package_install "gimp"
  package_install "firefox n1"
  aur_package_install "vivaldi-snapshot"
  aur_package_install "dropbox transmission-gtk spotify vlc openpht-git codecs64"
  package_install "ffmpeg"
  aur_package_install "gtk2-appmenu gtk3-appmenu profile-sync-daemon"

}

install_servers() {
  install_mariadb() {
    package_install "mariadb"
    /usr/bin/mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    system_ctl enable mysqld.service
    systemctl start mysqld.service
    /usr/bin/mysql_secure_installation
  }
  create_sites_folder() {
    [[ ! -f  /etc/httpd/conf/extra/httpd-userdir.conf.aui ]] && cp -v /etc/httpd/conf/extra/httpd-userdir.conf /etc/httpd/conf/extra/httpd-userdir.conf.aui
    replace_line 'public_html' 'Sites' /etc/httpd/conf/extra/httpd-userdir.conf
    su - ${username} -c "mkdir -p ~/Sites"
    su - ${username} -c "chmod o+x ~/ && chmod -R o+x ~/Sites"
    print_line
    echo "The folder \"Sites\" has been created in your home"
    echo "You can access your projects at \"http://localhost/~username\""
    pause_function
  }
  install_adminer() {
    aur_package_install "adminer"
    local ADMINER=`cat /etc/httpd/conf/httpd.conf | grep Adminer`
    [[ -z $ADMINER ]] && echo -e '\n# Adminer Configuration\nInclude conf/extra/httpd-adminer.conf' >> /etc/httpd/conf/httpd.conf
  }
  configure_php() {
    if [[ -f /etc/php/php.ini.pacnew ]]; then
      mv -v /etc/php/php.ini /etc/php/php.ini.pacold
      mv -v /etc/php/php.ini.pacnew /etc/php/php.ini
      rm -v /etc/php/php.ini.aui
    fi
    [[ -f /etc/php/php.ini.aui ]] && echo "/etc/php/php.ini.aui" || cp -v /etc/php/php.ini /etc/php/php.ini.aui
    if [[ $1 == mariadb ]]; then
      sed -i '/mysqli.so/s/^;//' /etc/php/php.ini
      sed -i '/mysql.so/s/^;//' /etc/php/php.ini
      sed -i '/skip-networking/s/^/#/' /etc/mysql/my.cnf
    else
      sed -i '/pgsql.so/s/^;//' /etc/php/php.ini
    fi
    sed -i '/mcrypt.so/s/^;//' /etc/php/php.ini
    sed -i '/gd.so/s/^;//' /etc/php/php.ini
    sed -i '/display_errors=/s/off/on/' /etc/php/php.ini
  }
  configure_php_apache() {
    if [[ -f /etc/httpd/conf/httpd.conf.pacnew ]]; then
      mv -v /etc/httpd/conf/httpd.conf.pacnew /etc/httpd/conf/httpd.conf
      rm -v /etc/httpd/conf/httpd.conf.aui
    fi
    [[ -f /etc/httpd/conf/httpd.conf.aui ]] && echo "/etc/httpd/conf/httpd.conf.aui" || cp -v /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.aui
    local IS_DISABLED=`cat /etc/httpd/conf/httpd.conf | grep php5_module.conf`
    if [[ -z $IS_DISABLED ]]; then
      echo -e 'application/x-httpd-php5                php php5' >> /etc/httpd/conf/mime.types
      sed -i '/LoadModule dir_module modules\/mod_dir.so/a\LoadModule php5_module modules\/libphp5.so' /etc/httpd/conf/httpd.conf
      echo -e '\n# Use for PHP 5.x:\nInclude conf/extra/php5_module.conf\n\nAddHandler php5-script php' >> /etc/httpd/conf/httpd.conf
      #  libphp5.so included with php-apache does not work with mod_mpm_event (FS#39218). You'll have to use mod_mpm_prefork instead
      replace_line 'LoadModule mpm_event_module modules/mod_mpm_event.so' 'LoadModule mpm_prefork_module modules/mod_mpm_prefork.so' /etc/httpd/conf/httpd.conf
      replace_line 'DirectoryIndex\ index.html' 'DirectoryIndex\ index.html\ index.php' /etc/httpd/conf/httpd.conf
    fi
  }

  [[ ${PMS} == 1 ]] && package_install plex-media-server && system_ctl enable plexmediaserver.service
  if [[ ${WEB} == 1 ]]; then
    package_install "apache php php-apache php-mcrypt php-gd"
    install_mariadb
    install_adminer
    system_ctl enable httpd.service
    configure_php_apache
    configure_php "mariadb"
    create_sites_folder
  fi
}

reconfigure_system() {
  hostnamectl set-hostname `cat basefuncs | grep host_name | sed 's/host_name=// ; s/"//g'`
  timedatectl set-timezone Europe/Stockholm
  timedatectl set-local-rtc false
  timedatectl set-ntp true

  if [[ ! -f /home/${username}/.config/gtk-3.0/settings.ini ]]; then
    run_as_user "echo -e \"[Settings]\ngtk-shell-shows-menubar = 1\" > /home/${username}/.config/gtk-3.0/settings.ini"
  else
    add_line "gtk-shell-shows-menubar = 1" "/home/${username}/.config/gtk-3.0/settings.ini"
  fi

  run_as_user "psd"
  run_as_user "sed -i '/USE_BACKUPS/s/^#//' /home/${username}/.config/psd/psd.conf"
}
