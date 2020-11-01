#!/bin/bash

#functions:
print_error() {
    #https://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
    printf "[ERROR] %s\n" "$1"
}

print_info(){
    printf "[Info] %s\n" "$1"
}

print_warning(){
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
    if ping "archlinux.org" -c 3 > /dev/null; then
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

show_disks_and_partitions(){
    print_info "Disks and partitions:"
    printf "\n"
    lsblk
    printf "\n"
    fdisk -l
}

partition_menu(){
 if fdisk -l | grep -i efi; then
    print_warning "There's already an EFI partition on that disk. Are you planing to dual boot?"
 else
    print_info "ok"
 fi
}

#disk type size
create_partition(){
if is_gpt_parition_table_created "$1";then
    case $2 in "efi") 
     if is_efi_parition_created "$1"; then
        echo "efi created"
     else
        echo "not created"
     fi
    ;;
    "swap") 
        printf "swap selected";;
    "root") 
        printf "root selected";;
    "home") 
        printf "home selected";;
    *) 
        printf "No supported partition type selected"
        ;;
    esac

    
    #if fdisk -l | grep -i efi; then
    #    print_warning "There's already an EFI partition on that disk. Are you planing to dual boot? (y/n):"
    #    read -r answer
    #    if [ "$answer" = "n" ]; then
    #     printf "exiting.."
    #     exit 1
    #    fi
    #     print_info "skipping creation of EFI partition"
    #else
    #    printf 'o\nn\np\n1\n\n\nw' | fdisk /dev/sda
    #fi
else
  print_warning "No GPT partition table was detected on $1. Would you like to wipe $1 and create the table? (y/n)"
  read -r answer
  if [ "$answer" = "n" ]; then
         printf "exiting.."
         exit 1
  else
   create_gpt_partition_table "$1" 2>/dev/null
   create_partition "$1" "efi"
  fi
fi
}

# when the disk has never been used or you want to clean it.
# arguments: disk (/dev/sda)
create_gpt_partition_table(){
    # wtf is &> ?
    printf 'g\nw\n' | fdisk "$1" &> /dev/null
}

# disk
is_efi_parition_created(){
    if printf "p\n" | fdisk "$1" | grep -i "efi" > /dev/null; then
      return 0
    else
      return 1
    fi
}

#disk
is_gpt_parition_table_created(){
    if printf "p\n" | fdisk "$1" | grep -i "gpt" > /dev/null; then
      return 0
    else
      return 1
    fi
}

partition_disk(){
    #https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script
    #(echo n; echo p; echo 1; echo 1; echo 200; echo w) | fdisk /dev/sdc
    exit 1
}

pre-installation_checks
update_system_clock
clear
show_disks_and_partitions
create_partition "/dev/sda" "efi"
