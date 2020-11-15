#!/bin/bash
set_time_zone(){
    print_info "Setting time zone"
    ln -sf /usr/share/zoneinfo/Toronto /etc/localtime
    # sleep required?
    hwclock --systohc
}

localization(){
    #https://stackoverflow.com/questions/24889346/how-to-uncomment-a-line-that-contains-a-specific-string-using-sed
    print_info "localization"
    sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
    sed -i '/fr_CA.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
}

# hostname
network_configuration(){
    echo "$1" > /etc/hostname
    printf "127.0.0.1   localhost\n" > /etc/hosts
    printf "::1         localhost\n" > /etc/hosts
    printf "127.0.1.1	%s.localdomain	%s #If the system has a permanent IP address, it should be used instead of 127.0.1.1\n" "$1" "$1" > /etc/hosts
}

# password
change_root_password() {
    printf "%s\n%s\n" "$1" "$1" | passwd
}

install_boot_loader(){
    #Installs GRUB
    pacman -Sy grub efibootmgr --noconfirm
    #A directory of that name will be created in esp/EFI/ to store the EFI binary and this is the name that will appear in the UEFI boot menu to identify
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
}

set_time_zone
localization
network_configuration "thinkpadT580" #wifi?
change_root_password "root"
#install_boot_loader