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
# disk
partition_disk() {
    if ! is_gpt_parition_table_created "$1"; then
        create_gpt_partition_table "$1"
    fi

    if ! is_efi_parition_created disk_selected ; then
        create_partition "$1" "efi" "$efi_size"
        #wait?
        format_partition "$1" "efi"
    fi
    create_partition "$1" "swap" "$swap_size"
    create_partition "$1" "root" "$root_size"
    create_partition "$1" "home" "$home_size"
    
    sleep 10

    format_partition "$1" "swap"
    format_partition "$1" "root"
    format_partition "$1" "home"

    sleep 10
    blockdev --rereadpt "$1"
    
    mount_partition "$1" "root"
    #important to create the mount points AFTER mounting the root partition
    create_mount_points
    mount_partition "$1" "efi"
    mount_partition "$1" "swap"
    mount_partition "$1" "home"
}

create_mount_points(){
    if ! [ -d "/mnt/boot" ]; then
        mkdir -p "/mnt/boot" 
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
        mount "$partition_location" "/mnt/boot"
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



install_essential_packages(){
    print_info "Installing essential packages"
    pacstrap /mnt base base-devel linux linux-firmware  man-db man-pages texinfo nano networkmanager git > /dev/null
}

generate_fstab(){
    print_info "Generating fstab"
    genfstab -U /mnt >> /mnt/etc/fstab
    print_info "Showing fstab"
    cat /mnt/etc/fstab
}

change_root(){
    print_info "Changing root to the new system"
    arch-chroot /mnt
}

pre-installation_tasks
show_disks_and_partitions
partition_disk "/dev/sda"
show_disks_and_partitions
install_essential_packages
generate_fstab
change_root

