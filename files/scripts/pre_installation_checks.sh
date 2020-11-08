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

pre-installation_checks() {
    check_boot_mode
    check_internet_connection
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

    create_gpt_partition_table "$disk_selected"

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

    #sleep 30
    #blockdev --rereadpt /dev/sda
    
    mount_partition "$disk_selected" "root"
    #impotant to create the mount points AFTER mounting the root partition
    create_mount_points
    mount_partition "$disk_selected" "efi"
    mount_partition "$disk_selected" "swap"
    mount_partition "$disk_selected" "home"

    #printf "Enter Root partition disk:"
    #read -r root_location
    #printf "Root partition size (Gb):"
    #read -r root_size

    #printf "Enter Swap partition disk:"
    #read -r swap_location
    #printf "Swap partition size (Gb):"
    #read -r swap_size

    #printf "Enter EFI partition disk:"
    #read -r efi_location
    #printf "EFI partition size (Gb):"
    #read -r efi_size
    #
    #printf "Enter Home partition disk:"
    #read -r home_location
    #printf "Home partition size (Gb):"
    #read -r home_size

    #format_partition "$efi_location" "efi"
    #format_partition "$swap_location" "swap"
    #format_partition "$root_location" "root"
    #format_partition "$home_location" "home"
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
    #if is_gpt_parition_table_created "$1";then
    #if [ "$1" = "efi" ]; then
    #    if is_efi_parition_created "$1"; then
    #        print_warning "There's already an EFI partition on that disk. Are you planing to dual boot? (y/n):"
    #        read -r answer
    #        if [ "$answer" = "n" ]; then
    #            printf "exiting.."
    #            exit 1
    #        else
    #            print_info "skipping creation of EFI partition"
    #        fi
    #    fi
    #else
    # (K,M,G,T,P) ?
    {
        printf "n\n\n\n+%sG\n" "$3"
        sleep 5
        printf "w\n"
    } | fdisk "$1" &>/dev/null
    sleep 5
    change_last_created_partition_type "$1" "$2"
    print_info "$2 partition created"
    #fi
    #else
    #    print_warning "No GPT partition table was detected on $1. Would you like to wipe $1 and create the table? (y/n)"
    #    read -r answer
    #    if [ "$answer" = "n" ]; then
    #        printf "exiting.."
    #        exit 1
    #    fi
    #    create_gpt_partition_table "$1" 2> /dev/null
    #    create_partition "$1" "$2" "$3"
    #fi
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
        mkswap -F "$partition_location" &> /dev/null
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

pre-installation_checks
update_system_clock
clear
show_disks_and_partitions
partition_disk
show_disks_and_partitions
