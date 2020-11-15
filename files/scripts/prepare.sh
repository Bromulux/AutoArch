#!/bin/bash
pre_installation() {
    check_boot_mode
    check_internet_connection
    update_system_clock
    install_required_packages
    rank_mirrors
}

check_boot_mode() {
    if [ -d "/sys/firmware/efi/efivars" ]; then
        print_info "Boot Mode [OK]"
        return 0
    else
        print_error "Boot mode is not UEFI."
        exit 1
    fi
}

check_internet_connection() {
    if ping "archlinux.org" -c 3 >/dev/null; then
        print_info "Internet Connection [OK]"
    else
        print_error "Not connected to the internet"
        exit 1
    fi
}

connect_wifi() {
    #todo
    #https://wiki.archlinux.org/index.php/Iwd#iwctl
    exit 1
}

update_system_clock() {
    timedatectl set-ntp true
    if timedatectl status | awk '/System clock synchronized: yes/ && /NTP service: active/'; then
        print_info "System clock update [OK]"
    else
        print_error "System clock not updated"
    fi
}



rank_mirrors(){
    #backup mirror list
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    curl -s "https://www.archlinux.org/mirrorlist/?country=CA&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist
}

install_required_packages(){
    pacman -Sy > /dev/null
    if ! pacman -Qi dosfstools &> /dev/null; then
        pacman -S dosfstools --noconfirm > /dev/null
    fi
    if ! pacman -Qi pacman-contrib &> /dev/null; then
        pacman -S pacman-contrib  --noconfirm  > /dev/null
    fi  
}

pre_installation