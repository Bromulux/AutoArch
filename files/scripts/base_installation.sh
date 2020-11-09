#!/bin/bash

#functions:
print_error() {
    #https://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
    printf "[ERROR] %s\n" "$1"
}

print_info() {
    printf "[Info] %s\n" "$1"
}

print_warning() {
    printf "[WARNING] %s:" "$1"
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

pre-installation_tasks() {
    check_boot_mode
    check_internet_connection
    rank_mirrors
    install_required_packages
}

install_required_packages(){
    pacman -Sy > /dev/null
    if ! pacman -Qi dosfstools > /dev/null; then
        pacman -S dosfstools --noconfirm > /dev/null
    fi
    if ! pacman -Qi pacman-contrib > /dev/null; then
        pacman -S pacman-contrib  --noconfirm  > /dev/null
    fi  
}


show_disks_and_partitions() {
    print_info "Disks and partitions:"
    printf "\n"
    lsblk -f
    printf "\n"
    fdisk -l
}

partition_disk() {
    printf "Enter disk:"
    read -r disk_selected
 
    if ! is_gpt_parition_table_created "$disk_selected"; then
        create_gpt_partition_table "$disk_selected"
    fi

    printf "EFI partition size (Gb):"
    read -r efi_size

    printf "Swap partition size (Gb):"
    read -r swap_size

    printf "Root partition size (Gb):"
    read -r root_size

    printf "Home partition size (Gb):"
    read -r home_size

    create_partition "$disk_selected" "efi" "$efi_size"
    create_partition "$disk_selected" "swap" "$swap_size"
    create_partition "$disk_selected" "root" "$root_size"
    create_partition "$disk_selected" "home" "$home_size"
    
    sleep 10

    format_partition "$disk_selected" "efi"
    format_partition "$disk_selected" "swap"
    format_partition "$disk_selected" "root"
    format_partition "$disk_selected" "home"

    sleep 10
    blockdev --rereadpt "$disk_selected"
    
    mount_partition "$disk_selected" "root"
    #impotant to create the mount points AFTER mounting the root partition
    create_mount_points
    mount_partition "$disk_selected" "efi"
    mount_partition "$disk_selected" "swap"
    mount_partition "$disk_selected" "home"
}

create_mount_points(){
    if ! [ -d "/mnt/boot/efi" ]; then
        mkdir -p "/mnt/boot/efi" 
    fi
    if ! [ -d "/mnt/home" ]; then
        mkdir "/mnt/home"
    fi
    
}

#disk type size
create_partition() {
    # (K,M,G,T,P) ?
    {
        printf "n\n\n\n+%sG\n" "$3"
        sleep 5
        printf "w\n"
    } | fdisk "$1" &>/dev/null
    sleep 5
    change_last_created_partition_type "$1" "$2"
    print_info "$2 partition created"
}

# when the disk has never been used or you want to clean it.
# disk
create_gpt_partition_table() {
    # wtf is &> ?
    printf 'g\nw\n' | fdisk "$1" &>/dev/null
}
#disk or partition location
wipe_filesystem_and_partition_table() {
    wipefs -a -f "$1" > /dev/null
}


# disk
is_efi_parition_created() {
    if printf "p\n" | fdisk "$1" | grep -i "efi" >/dev/null; then
        return 0
    else
        return 1
    fi
}

#disk
is_gpt_parition_table_created() {
    if printf "p\n" | fdisk "$1" | grep -i "gpt" >/dev/null; then
        return 0
    else
        return 1
    fi
}
#disk type
change_last_created_partition_type() {
    EFI_TYPE_CODE="1"
    SWAP_TYPE_CODE="19"
    ROOT_TYPE_CODE="24"
    HOME_TYPE_CODE="28"

    case $2 in "efi")
        printf "t\n\n%s\nw\n" "$EFI_TYPE_CODE" | fdisk "$1" >/dev/null
        ;;
    "swap")
        printf "t\n\n%s\nw\n" "$SWAP_TYPE_CODE" | fdisk "$1" >/dev/null
        ;;
    "root")
        printf "t\n\n%s\nw\n" "$ROOT_TYPE_CODE" | fdisk "$1" >/dev/null
        ;;
    "home")
        printf "t\n\n%s\nw\n" "$HOME_TYPE_CODE" | fdisk "$1" >/dev/null
        ;;
    *)
        printf "No supported partition type selected"
        ;;
    esac
}
# parition_location partition_format
# disk type
format_partition() {
    #note: file -sL /dev/sdaX to check the filesystem
    case $2 in "efi")
        partition_location=$(printf "p\n" | fdisk "$1" | grep -i "$2" | grep -o -E "^\/dev\/[a-z]+[1-9]")
        mkfs.fat -F32 "$partition_location" &> /dev/null
        printf "[Info] FAT32 file system created on $2 partition %s\n" "$partition_location"
        ;;
    "swap")
        partition_location=$(printf "p\n" | fdisk "$1" | grep -i "$2" | grep -o -E "^\/dev\/[a-z]+[1-9]")
        mkswap "$partition_location" &> /dev/null
        printf "[Info] Swap file system created on $2 partition %s\n" "$partition_location"
        ;;
    "root")
        partition_location=$(printf "p\n" | fdisk "$1" | grep -i "$2" | grep -o -E "^\/dev\/[a-z]+[1-9]")
        mkfs.ext4 -F "$partition_location" &> /dev/null
        printf "[Info] EXT4 file system created on $2 partition %s\n" "$partition_location"
        ;;
    "home")
        partition_location=$(printf "p\n" | fdisk "$1" | grep -i "$2" | grep -o -E "^\/dev\/[a-z]+[1-9]")
        mkfs.ext4 -F "$partition_location" &> /dev/null
        printf "[Info] EXT4 file system created on $2 partition %s\n" "$partition_location"
        ;;
    *)
        printf "No supported partition type selected"
        ;;
    esac
}

#disk partition
mount_partition(){
    case $2 in "efi")
        partition_location=$(printf "p\n" | fdisk "$1" | grep -i "$2" | grep -o -E "^\/dev\/[a-z]+[1-9]")
        mount "$partition_location" "/mnt/boot/efi"
        #sleep 5
    ;;
    "swap")
        partition_location=$(printf "p\n" | fdisk "$1" | grep -i "$2" | grep -o -E "^\/dev\/[a-z]+[1-9]")
        swapon "$partition_location"
        #sleep 5
    ;;
    "root")
        partition_location=$(printf "p\n" | fdisk "$1" | grep -i "$2" | grep -o -E "^\/dev\/[a-z]+[1-9]")
        mount "$partition_location" "/mnt"
        #sleep 5
    ;;
    "home")
        partition_location=$(printf "p\n" | fdisk "$1" | grep -i "$2" | grep -o -E "^\/dev\/[a-z]+[1-9]")
        mount "$partition_location" "/mnt/home"
        #sleep 5
    ;;
    *)
    ;;
    esac
}

rank_mirrors(){
    #backup mirror list
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    curl -s "https://www.archlinux.org/mirrorlist/?country=CA&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist
}

install_essential_packages(){
    pacstrap /mnt base base-devel linux linux-firmware  man-db man-pages texinfo nano networkmanager git > /dev/null
}

generate_fstab(){
    genfstab -U /mnt >> /mnt/etc/fstab
    print_info "Showing fstab"
    cat /mnt/etc/fstab
}

change_root(){
    arch-chroot /mnt
}
##############################################################################################################################################################################################
set_time_zone(){
    ln -sf /usr/share/zoneinfo/Toronto /etc/localtime
    # sleep required?
    hwclock --systohc
}

update_system_clock
pre-installation_tasks
clear
show_disks_and_partitions
partition_disk
show_disks_and_partitions
install_essential_packages
generate_fstab

change_root

set_time_zone